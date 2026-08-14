# frozen_string_literal: true

FactoryBot.define do
  factory :transparency_log_inclusion_observation do
    signed_event_envelope { association(:transparency_log_signed_event_envelope) }
    delivery do
      association(
        :transparency_log_delivery,
        event: signed_event_envelope.event,
        log_identity: signed_event_envelope.log_identity,
        signed_event_envelope:
      )
    end
    log_identity { signed_event_envelope.log_identity }
    log_index { 0 }
    observed_via { "submission_201" }
    observed_at { Time.current }
    rekor_response { '{"uuid":"entry-uuid"}' if observed_via.to_s == "submission_201" }
    rekor_response_sha256 { Digest::SHA256.digest(rekor_response) if rekor_response }
    entry_bundle { "entry-bundle" }
    entry_bundle_sha256 { Digest::SHA256.digest(entry_bundle) }
    checkpoint { "rekor.example checkpoint" }
    checkpoint_sha256 { Digest::SHA256.digest(checkpoint) }
    leaf_hash { Digest::SHA256.digest("leaf") }
    root_hash { Digest::SHA256.digest("root") }
    proof_hashes { [] }
    tree_size { 1 }
    verification_policy_id { "rekor-v2-default" }
    verified_at { Time.current }

    trait :duplicate_reconciliation do
      observed_via { "duplicate_409_reconciliation" }
    end
  end
end
