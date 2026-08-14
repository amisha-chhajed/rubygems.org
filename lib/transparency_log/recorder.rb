# frozen_string_literal: true

require "digest"

class TransparencyLog::Recorder
  def initialize
    @signer = TransparencyLog::Signer.new
    @entry_builder = TransparencyLog::EntryBuilder.new
  end

  def record(attributes, enqueue: true)
    event = TransparencyLogEvent.new(attributes)

    event.assign_attributes(
      spec_version: "1.0",
      canonicalization_algorithm: "JCS",
      canonicalization_version: "1",
      signing_mode: "server"
    )

    canonical_payload =
      TransparencyLogEvent::CanonicalPayload.from_event(event).to_h
    canonical_payload_bytes = canonical_payload.to_json

    event.canonical_payload = canonical_payload
    event.assign_attributes(@signer.sign(canonical_payload_bytes))
    event.rekor_request_body = @entry_builder.build(event)
    rekor_request_bytes = event.rekor_request_body.to_json

    ActiveRecord::Base.transaction do
      event.save!
      envelope = create_envelope(event, canonical_payload_bytes, rekor_request_bytes)
      create_delivery(event, envelope)
    end

    ProcessTransparencyLogEventJob.perform_later(event) if enqueue
    event
  end

  private

  def create_envelope(event, canonical_payload, rekor_request)
    event.signed_event_envelopes.create!(
      log_identity: TransparencyLog.configuration.log_identity,
      canonical_payload:,
      payload_sha256: event.payload_digest,
      service_key_id: event.public_key_id,
      signing_algorithm: event.signing_algorithm,
      signature: event.signature,
      public_key_der: event.public_key_der,
      rekor_request:,
      rekor_request_sha256: Digest::SHA256.digest(rekor_request)
    )
  end

  def create_delivery(event, envelope)
    event.deliveries.create!(
      log_identity: TransparencyLog.configuration.log_identity,
      signed_event_envelope: envelope,
      phase: :ready_to_submit,
      signing_attempt_count: 1
    )
  end
end
