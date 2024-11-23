require "csv"
require "nokogiri"
require "algolia"
require "dotenv"
require "json"
require "securerandom"
Dotenv.load

namespace :rebuild do
  desc "Reindex patients' data to Algolia"
  task :reindex do
    begin
      app_id = ENV["ALGOLIA_APP_ID"]
      api_key = ENV["ALGOLIA_API_KEY"]
      index_name = ENV["ALGOLIA_INDEX_NAME"]

      raise "Missing env" if app_id.nil? || api_key.nil? || index_name.nil?

      client = Algolia::SearchClient.create(app_id, api_key)
      Dir.glob("data*.csv").each do |file|
        CSV.foreach(file, headers: true) do |row|
          medical_history = []
          begin
            medical_history = eval(row["Histórico Médico"])
          rescue
          end

          data = {
            objectID: SecureRandom.uuid,
            name: row["Nome"],
            date_of_birth: row["Data de Nascimento"],
            origin_city: row["Cidade de Origem"],
            residence_city: row["Cidade onde Reside"],
            medical_history: medical_history
          }
          client.save_object(
            index_name = index_name,
            body = data
          )
        end
      end

      Dir.glob("data*.xml").each do |file|
        xml = Nokogiri::XML(File.read(file))

        xml.xpath("//Paciente").each do |paciente|
          nome = paciente.at_xpath("Nome")&.text
          data_nascimento = paciente.at_xpath("DataNascimento")&.text
          cidade_origem = paciente.at_xpath("CidadeDeOrigem")&.text
          cidade_reside = paciente.at_xpath("CidadeOndeReside")&.text

          medical_history = []
          paciente.xpath("HistoricoMedico/Caso").each do |caso|
            medical_history << {
              cidade: caso.at_xpath("Cidade")&.text,
              estado: caso.at_xpath("Estado")&.text,
              doenca: caso.at_xpath("Doenca")&.text,
              data: caso.at_xpath("Data")&.text
            }
          end

          data = {
            objectID: SecureRandom.uuid,
            name: nome,
            date_of_birth: data_nascimento,
            origin_city: cidade_origem,
            residence_city: cidade_reside,
            medical_history: medical_history
          }

          client.save_object(
            index_name = index_name,
            body = data
          )
        end
      end

      puts "Reindexing completed successfully!"
    rescue => e
      puts "Error during reindexing: #{e.message}"
    end
  end
end
