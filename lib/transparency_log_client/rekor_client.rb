# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Tlog
  class RekorClient
    ENTRIES_PATH = "/api/v2/log/entries"

    def initialize(url:)
      @base_uri = URI.parse(url)
      @http     = Net::HTTP.new(@base_uri.host, @base_uri.port)
      @http.use_ssl = @base_uri.scheme == "https"
    end

    def post_entry(entry)
      response = @http.post(
        ENTRIES_PATH,
        JSON.dump(entry),
        headers
      )
      handle_response(response, expected: "201")
    end

    private

    def headers
      {
        "Content-Type" => "application/json",
        "Accept"       => "application/json"
      }
    end

    def handle_response(response, expected:)
      unless response.code == expected
        raise "Unexpected response #{response.code}: #{response.body}"
      end

      JSON.parse(response.body)
    end
  end
end