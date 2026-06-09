require_relative "payload_builder"
require_relative "rekor_client"
require "json"

test_data = { "user" => "alice", "action" => "commit" }

output = Tlog::PayloadBuilder.build(test_data)

pp output

puts JSON.pretty_generate(output)

rekor_client = Tlog::RekorClient.new(url: "http://localhost:3004")
response = rekor_client.post_entry(output)
puts "Response: #{response}"
