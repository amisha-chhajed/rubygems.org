# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/transparency_log_client/payload_builder"

class PayloadBuilderTest < Minitest::Test
  def test_build
    json_payload = { "user" => "alice", "action" => "commit" }
    result = Tlog::PayloadBuilder.build(json_payload)
    assert_includes(result.keys, "hashedRekordRequestV002")
    assert_includes(result["hashedRekordRequestV002"].keys, "digest")
    assert_includes(result["hashedRekordRequestV002"].keys, "signature")
  end
end
