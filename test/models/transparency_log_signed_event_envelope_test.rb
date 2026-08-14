# frozen_string_literal: true

require "test_helper"

class TransparencyLogSignedEventEnvelopeTest < ActiveSupport::TestCase
  should "link to an existing event through its event uuid" do
    event = create(:transparency_log_event, :request_built)
    envelope = create(:transparency_log_signed_event_envelope, event:)

    assert_equal event.event_uuid, envelope.event_id
    assert_equal event, envelope.event
    assert_equal [envelope], event.signed_event_envelopes.to_a
  end

  should "link a replacement envelope without changing its predecessor" do
    predecessor = create(:transparency_log_signed_event_envelope)
    successor = create(
      :transparency_log_signed_event_envelope,
      event: predecessor.event,
      log_identity: predecessor.log_identity,
      supersedes_envelope: predecessor
    )

    assert_equal predecessor, successor.supersedes_envelope
    assert_equal successor, predecessor.successor_envelope
  end

  should "reject updates after creation" do
    envelope = create(:transparency_log_signed_event_envelope)

    refute envelope.update(log_identity: "other-log.example")
    assert_includes envelope.errors[:base], "signed event envelopes are immutable"
    assert_equal "rekor.example", envelope.reload.log_identity
  end

  should "reject destruction after creation" do
    envelope = create(:transparency_log_signed_event_envelope)

    refute envelope.destroy
    assert_includes envelope.errors[:base], "signed event envelopes are immutable"
    assert_predicate envelope.reload, :persisted?
  end
end
