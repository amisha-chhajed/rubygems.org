# frozen_string_literal: true

class TransparencyLogSignedEventEnvelope < ApplicationRecord
  include TransparencyLog::ImmutableRecord

  belongs_to :event,
    class_name: "TransparencyLogEvent",
    primary_key: :event_uuid,
    inverse_of: :signed_event_envelopes
  belongs_to :supersedes_envelope,
    class_name: "TransparencyLogSignedEventEnvelope",
    optional: true,
    inverse_of: :successor_envelope

  has_one :successor_envelope,
    class_name: "TransparencyLogSignedEventEnvelope",
    foreign_key: :supersedes_envelope_id,
    inverse_of: :supersedes_envelope,
    dependent: :restrict_with_exception
  has_many :deliveries,
    class_name: "TransparencyLogDelivery",
    foreign_key: :signed_event_envelope_id,
    inverse_of: :signed_event_envelope,
    dependent: :restrict_with_exception
  has_many :inclusion_observations,
    class_name: "TransparencyLogInclusionObservation",
    foreign_key: :signed_event_envelope_id,
    inverse_of: :signed_event_envelope,
    dependent: :restrict_with_exception

  validates :log_identity,
    :canonical_payload,
    :payload_sha256,
    :service_key_id,
    :signing_algorithm,
    :signature,
    :public_key_der,
    :rekor_request,
    :rekor_request_sha256,
    presence: true
  validates :log_identity, length: { maximum: 255 }
  validates :service_key_id, length: { maximum: 128 }
  validates :signing_algorithm, length: { maximum: 64 }
  validates :payload_sha256, :rekor_request_sha256, length: { is: 32 }
end
