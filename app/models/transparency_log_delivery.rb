# frozen_string_literal: true

class TransparencyLogDelivery < ApplicationRecord
  PHASES = {
    awaiting_envelope: "awaiting_envelope",
    ready_to_submit: "ready_to_submit",
    submitting: "submitting",
    reconciling: "reconciling",
    completed: "completed",
    quarantined: "quarantined"
  }.freeze

  ERROR_PHASES = %w[
    signing
    submission
    response_verification
    reconciliation
    invariant
  ].freeze

  belongs_to :event,
    class_name: "TransparencyLogEvent",
    primary_key: :event_uuid,
    inverse_of: :deliveries
  belongs_to :signed_event_envelope,
    class_name: "TransparencyLogSignedEventEnvelope",
    optional: true,
    inverse_of: :deliveries
  belongs_to :completion_observation,
    class_name: "TransparencyLogInclusionObservation",
    optional: true

  has_many :inclusion_observations,
    class_name: "TransparencyLogInclusionObservation",
    foreign_key: :delivery_id,
    inverse_of: :delivery,
    dependent: :restrict_with_exception

  enum :phase, PHASES, default: :awaiting_envelope, validate: true

  validates :log_identity, presence: true, length: { maximum: 255 }
  validates :signing_attempt_count,
    :submission_attempt_count,
    :reconciliation_attempt_count,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :last_error_phase, inclusion: { in: ERROR_PHASES }, allow_nil: true
  validates :last_error_code, length: { maximum: 100 }
  validates :last_error_detail, length: { maximum: 500 }

  validate :signed_event_envelope_matches_delivery
  validate :completion_observation_matches_delivery

  private

  def signed_event_envelope_matches_delivery
    return unless signed_event_envelope

    errors.add(:signed_event_envelope, "must belong to the delivery event") if event_id != signed_event_envelope.event_id
    errors.add(:signed_event_envelope, "must target the delivery log") if log_identity != signed_event_envelope.log_identity
  end

  def completion_observation_matches_delivery
    return unless completion_observation

    errors.add(:completion_observation, "must belong to this delivery") if completion_observation.delivery_id != id
    return unless signed_event_envelope_id
    return if completion_observation.signed_event_envelope_id == signed_event_envelope_id

    errors.add(:completion_observation, "must observe the delivery envelope")
  end
end
