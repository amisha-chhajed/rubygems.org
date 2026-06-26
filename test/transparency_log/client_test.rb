# frozen_string_literal: true

require "test_helper"

class TransparencyLog::ClientTest < ActiveSupport::TestCase
  setup do
    @transparency_log_entry = create(:transparency_log_event)
    @client = TransparencyLog::Client.new("http://example.test")
  end

  test "posts entry to rekor log entries endpoint" do
    payload = TransparencyLog::EntryBuilder.build(@transparency_log_entry)

    stub_request(:post, "http://example.test/api/v2/log/entries")
      .to_return(
        status: 201,
        body: { uuid: "abc", logIndex: 1 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = @client.post(payload)

    assert_equal "201", response.code
    assert_equal(
      { "uuid" => "abc", "logIndex" => 1 },
      JSON.parse(response.body)
    )
  end

  test "raises an error when HTTP 500"
  test "raises an error when connection failed"
  test "raisea an error when connection timed out"
end
