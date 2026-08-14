# frozen_string_literal: true

require "test_helper"

class TransparencyLog::RecorderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @attributes = attributes_for(:transparency_log_event)
    @recorder = TransparencyLog::Recorder.new
  end

  test "prepares saves and enqueues transparency log event" do
    assert_enqueued_jobs 1, only: ProcessTransparencyLogEventJob do
      @recorder.record(@attributes)
    end

    transparency_log_event = TransparencyLogEvent.order(:id).last

    expected_payload =
      TransparencyLogEvent::CanonicalPayload
        .from_event(transparency_log_event)
        .to_h

    expected_request =
      TransparencyLog::EntryBuilder.new.build(transparency_log_event)

    assert_predicate transparency_log_event, :persisted?
    assert_predicate transparency_log_event, :valid?

    assert_equal "1.0", transparency_log_event.spec_version
    assert_equal "JCS", transparency_log_event.canonicalization_algorithm
    assert_equal "1", transparency_log_event.canonicalization_version
    assert_equal "server", transparency_log_event.signing_mode

    assert_equal expected_payload, transparency_log_event.canonical_payload
    assert_equal expected_request, transparency_log_event.rekor_request_body

    assert_predicate transparency_log_event.payload_digest, :present?
    assert_predicate transparency_log_event.signature, :present?
    assert_predicate transparency_log_event.public_key_der, :present?

    assert_nil transparency_log_event.rekor_response_body
  end

  test "can prepare and save an event without enqueueing it" do
    event = nil

    assert_no_enqueued_jobs only: ProcessTransparencyLogEventJob do
      event = @recorder.record(@attributes, enqueue: false)
    end

    assert_predicate event, :persisted?
    assert_predicate event, :pending?
  end

  test "creates a signed envelope and ready delivery for the configured log" do
    event = @recorder.record(@attributes, enqueue: false)

    envelope = event.signed_event_envelopes.sole
    delivery = event.deliveries.sole

    assert_equal TransparencyLog.configuration.log_identity, envelope.log_identity
    assert_equal TransparencyLog.configuration.log_identity, delivery.log_identity
    assert_equal envelope, delivery.signed_event_envelope
    assert_predicate delivery, :ready_to_submit?
    assert_equal 1, delivery.signing_attempt_count
  end

  test "stores the exact signed payload and Rekor request bytes in the envelope" do
    event = @recorder.record(@attributes, enqueue: false)
    envelope = event.signed_event_envelopes.sole

    expected_payload = event.canonical_payload.to_json
    expected_request = event.rekor_request_body.to_json
    public_key = OpenSSL::PKey.read(envelope.public_key_der)

    assert_equal expected_payload, envelope.canonical_payload
    assert_equal Digest::SHA256.digest(expected_payload), envelope.payload_sha256
    assert_equal event.payload_digest, envelope.payload_sha256
    assert public_key.verify(OpenSSL::Digest.new("SHA256"), envelope.signature, envelope.canonical_payload)

    assert_equal expected_request, envelope.rekor_request
    assert_equal Digest::SHA256.digest(expected_request), envelope.rekor_request_sha256
  end

  test "rolls back all records and enqueueing when persistence fails" do
    original_log_identity = TransparencyLog.configuration.log_identity
    TransparencyLog.configuration.log_identity = nil
    counts = [TransparencyLogEvent, TransparencyLogSignedEventEnvelope, TransparencyLogDelivery].index_with(&:count)

    assert_no_enqueued_jobs only: ProcessTransparencyLogEventJob do
      assert_raises(ActiveRecord::RecordInvalid) do
        @recorder.record(@attributes)
      end
    end

    counts.each do |model, count|
      assert_equal count, model.count
    end
  ensure
    TransparencyLog.configuration.log_identity = original_log_identity
  end
end
