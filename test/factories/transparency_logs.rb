# frozen_string_literal: true

FactoryBot.define do
  factory :transparency_log do
    events_type { "MyString" }
    body { "" }
  end
end
