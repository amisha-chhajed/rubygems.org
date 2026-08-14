# frozen_string_literal: true

FactoryBot.define do
  factory :transparency_log_signed_event_envelope do
    event { association(:transparency_log_event, :request_built) }
    log_identity { "rekor.example" }
    canonical_payload { event.canonical_payload.to_json }
    payload_sha256 { Digest::SHA256.digest(canonical_payload) }
    service_key_id { event.public_key_id }
    signing_algorithm { event.signing_algorithm }
    signature { event.signature }
    public_key_der { event.public_key_der }
    rekor_request { event.rekor_request_body.to_json }
    rekor_request_sha256 { Digest::SHA256.digest(rekor_request) }
  end
end
