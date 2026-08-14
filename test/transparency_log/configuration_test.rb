# frozen_string_literal: true

require "test_helper"

class TransparencyLog::ConfigurationTest < ActiveSupport::TestCase
  setup do
    @config = TransparencyLog::Configuration.new
  end

  test "#rekor_url" do
    @config.rekor_url = "https://example.com"

    assert_equal "https://example.com", @config.rekor_url
  end

  test "#private_key" do
    @config.private_key = "my_private_key"

    assert_equal "my_private_key", @config.private_key
  end

  test "#log_identity" do
    @config.log_identity = "rekor.example"

    assert_equal "rekor.example", @config.log_identity
  end
end
