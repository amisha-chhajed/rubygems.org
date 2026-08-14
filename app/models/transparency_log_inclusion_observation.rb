# frozen_string_literal: true

class TransparencyLogInclusionObservation < ApplicationRecord
  include TransparencyLog::ImmutableRecord

  OBSERVATION_SOURCES = {
    "submission_201" => "submission_201",
    "duplicate_409_reconciliation" => "duplicate_409_reconciliation"
  }.freeze

  belongs_to :delivery,
    class_name: "TransparencyLogDelivery",
    inverse_of: :inclusion_observations
  belongs_to :signed_event_envelope,
    class_name: "TransparencyLogSignedEventEnvelope",
    inverse_of: :inclusion_observations

  enum :observed_via, OBSERVATION_SOURCES, validate: true

  validates :log_identity,
    :observed_at,
    :entry_bundle,
    :entry_bundle_sha256,
    :checkpoint,
    :checkpoint_sha256,
    :leaf_hash,
    :root_hash,
    :verification_policy_id,
    :verified_at,
    presence: true
  validates :log_identity, :verification_policy_id, length: { maximum: 255 }
  validates :log_index, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :tree_size, numericality: { only_integer: true, greater_than: 0 }
  validates :rekor_response_sha256, length: { is: 32 }, allow_nil: true
  validates :entry_bundle_sha256,
    :checkpoint_sha256,
    :leaf_hash,
    :root_hash,
    length: { is: 32 }

  validate :matches_delivery
  validate :response_matches_observation_source
  validate :log_index_is_within_tree

  private

  def matches_delivery
    return unless delivery && signed_event_envelope

    errors.add(:signed_event_envelope, "must be the delivery envelope") if delivery.signed_event_envelope != signed_event_envelope
    errors.add(:signed_event_envelope, "must belong to the delivery event") if delivery.event_id != signed_event_envelope.event_id
    return if log_identity == delivery.log_identity && log_identity == signed_event_envelope.log_identity

    errors.add(:log_identity, "must match the delivery and signed event envelope")
  end

  def response_matches_observation_source
    if submission_201?
      errors.add(:rekor_response, "must be present for a submission observation") if rekor_response.blank?
      errors.add(:rekor_response_sha256, "must be present for a submission observation") if rekor_response_sha256.blank?
    elsif duplicate_409_reconciliation?
      errors.add(:rekor_response, "must be absent for a duplicate reconciliation observation") if rekor_response.present?
      errors.add(:rekor_response_sha256, "must be absent for a duplicate reconciliation observation") if rekor_response_sha256.present?
    end
  end

  def log_index_is_within_tree
    return unless log_index.is_a?(Integer) && tree_size.is_a?(Integer)
    return if log_index < tree_size

    errors.add(:log_index, "must be less than tree size")
  end
end
