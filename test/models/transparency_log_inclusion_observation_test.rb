# frozen_string_literal: true

require "test_helper"

class TransparencyLogInclusionObservationTest < ActiveSupport::TestCase
  should "link one delivery to the envelope observed in its log" do
    observation = create(:transparency_log_inclusion_observation)

    assert_equal observation.delivery.signed_event_envelope, observation.signed_event_envelope
    assert_equal observation.delivery.log_identity, observation.log_identity
    assert_equal [observation], observation.delivery.inclusion_observations.to_a
    assert_equal [observation], observation.signed_event_envelope.inclusion_observations.to_a
  end

  should "be usable as the mutable delivery completion pointer" do
    observation = create(:transparency_log_inclusion_observation)
    delivery = observation.delivery

    assert delivery.update(completion_observation: observation, phase: :completed)
    assert_equal observation, delivery.reload.completion_observation
  end

  should "reject an envelope other than the delivery envelope" do
    observation = build(:transparency_log_inclusion_observation)
    observation.signed_event_envelope = build(
      :transparency_log_signed_event_envelope,
      event: observation.delivery.event,
      log_identity: observation.delivery.log_identity
    )

    refute_predicate observation, :valid?
    assert_includes observation.errors[:signed_event_envelope], "must be the delivery envelope"
  end

  should "require a response and digest for a submission observation" do
    observation = build(
      :transparency_log_inclusion_observation,
      observed_via: "submission_201",
      rekor_response: nil,
      rekor_response_sha256: nil
    )

    refute_predicate observation, :valid?
    assert_includes observation.errors[:rekor_response], "must be present for a submission observation"
  end

  should "exclude a response from a duplicate reconciliation observation" do
    observation = build(
      :transparency_log_inclusion_observation,
      :duplicate_reconciliation,
      rekor_response: "unexpected response",
      rekor_response_sha256: Digest::SHA256.digest("unexpected response")
    )

    refute_predicate observation, :valid?
    assert_includes observation.errors[:rekor_response], "must be absent for a duplicate reconciliation observation"
  end

  should "reject an index outside the observed tree" do
    observation = build(:transparency_log_inclusion_observation, log_index: 3, tree_size: 3)

    refute_predicate observation, :valid?
    assert_includes observation.errors[:log_index], "must be less than tree size"
  end

  should "reject updates after creation" do
    observation = create(:transparency_log_inclusion_observation)

    refute observation.update(verification_policy_id: "other-policy")
    assert_includes observation.errors[:base], "inclusion observations are immutable"
    assert_equal "rekor-v2-default", observation.reload.verification_policy_id
  end

  should "reject destruction after creation" do
    observation = create(:transparency_log_inclusion_observation)

    refute observation.destroy
    assert_includes observation.errors[:base], "inclusion observations are immutable"
    assert_predicate observation.reload, :persisted?
  end
end
