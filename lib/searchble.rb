require "csv"
require "algolia"
require "dotenv"

class Searchble
  def self.search
    app_id = ENV["ALGOLIA_APP_ID"]
    api_key = ENV["ALGOLIA_API_KEY"]
    index_name = ENV["ALGOLIA_INDEX_NAME"]

    client = Algolia::SearchClient.create(app_id, api_key)

    results = client.search(
      search_method_params = {
        requests: [ { indexName: index_name, query: "covid" } ]
      }
    )

    results
  end
end
