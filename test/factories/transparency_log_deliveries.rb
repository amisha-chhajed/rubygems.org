# frozen_string_literal: true

FactoryBot.define do
  factory :transparency_log_delivery do
    event { association(:transparency_log_event, :request_built) }
    log_identity { "rekor.example" }
  end
end
