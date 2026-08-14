# frozen_string_literal: true

require "test_helper"

class TransparencyLogDeliveryTest < ActiveSupport::TestCase
  should "link to an existing event through its event uuid" do
    event = create(:transparency_log_event, :request_built)
    delivery = create(:transparency_log_delivery, event:)

    assert_equal event.event_uuid, delivery.event_id
    assert_equal event, delivery.event
    assert_equal [delivery], event.deliveries.to_a
  end

  should "start awaiting an envelope and remain mutable" do
    delivery = create(:transparency_log_delivery)

    assert_predicate delivery, :awaiting_envelope?
    assert delivery.update(phase: :ready_to_submit)
    assert_predicate delivery, :ready_to_submit?
  end

  should "accept an envelope for the same event and log" do
    envelope = create(:transparency_log_signed_event_envelope)
    delivery = build(
      :transparency_log_delivery,
      event: envelope.event,
      log_identity: envelope.log_identity,
      signed_event_envelope: envelope
    )

    assert_predicate delivery, :valid?
  end

  should "reject an envelope for a different event" do
    delivery = build(:transparency_log_delivery)
    delivery.signed_event_envelope = build(
      :transparency_log_signed_event_envelope,
      log_identity: delivery.log_identity
    )

    refute_predicate delivery, :valid?
    assert_includes delivery.errors[:signed_event_envelope], "must belong to the delivery event"
  end

  should "reject an envelope for a different log" do
    delivery = build(:transparency_log_delivery, log_identity: "rekor.example")
    delivery.signed_event_envelope = build(
      :transparency_log_signed_event_envelope,
      event: delivery.event,
      log_identity: "other-log.example"
    )

    refute_predicate delivery, :valid?
    assert_includes delivery.errors[:signed_event_envelope], "must target the delivery log"
  end

  should "reject negative attempt counts" do
    delivery = build(:transparency_log_delivery, submission_attempt_count: -1)

    refute_predicate delivery, :valid?
    assert_includes delivery.errors[:submission_attempt_count], "must be greater than or equal to 0"
  end
end
