# frozen_string_literal: true

require "test_helper"

class TlogTest < ActiveSupport::TestCase
  test "can be instantiated" do
    assert_instance_of TransparencyLog::Tlog, TransparencyLog::Tlog.new
  end
end
