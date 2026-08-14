# frozen_string_literal: true

class CreateTransparencyLogPersistenceTables < ActiveRecord::Migration[8.1]
  def change
    create_signed_event_envelopes
    create_deliveries
    create_inclusion_observations
    add_foreign_keys
  end

  private

  def create_signed_event_envelopes
    # Immutable records intentionally have no mutable timestamp columns.
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :transparency_log_signed_event_envelopes, id: :uuid do |t|
      t.uuid :event_id, null: false
      t.string :log_identity, null: false, limit: 255
      t.uuid :supersedes_envelope_id
      t.binary :canonical_payload, null: false
      t.binary :payload_sha256, null: false
      t.string :service_key_id, null: false, limit: 128
      t.string :signing_algorithm, null: false, limit: 64
      t.binary :signature, null: false
      t.binary :public_key_der, null: false
      t.binary :rekor_request, null: false
      t.binary :rekor_request_sha256, null: false

      t.index %i[event_id log_identity],
        unique: true,
        where: "supersedes_envelope_id IS NULL",
        name: "index_tlog_envelopes_on_event_log_root"
      t.index :supersedes_envelope_id, unique: true
      t.check_constraint "octet_length(payload_sha256) = 32",
        name: "tlog_envelopes_payload_sha256_length"
      t.check_constraint "octet_length(rekor_request_sha256) = 32",
        name: "tlog_envelopes_request_sha256_length"
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end

  def create_deliveries
    create_table :transparency_log_deliveries, id: :uuid do |t|
      t.uuid :event_id, null: false
      t.string :log_identity, null: false, limit: 255
      t.uuid :signed_event_envelope_id
      t.string :phase, null: false, limit: 32, default: "awaiting_envelope"
      t.integer :signing_attempt_count, null: false, default: 0
      t.integer :submission_attempt_count, null: false, default: 0
      t.integer :reconciliation_attempt_count, null: false, default: 0
      t.datetime :next_retry_at
      t.string :last_error_phase, limit: 32
      t.string :last_error_code, limit: 100
      t.string :last_error_detail, limit: 500
      t.datetime :last_error_at
      t.uuid :completion_observation_id
      t.timestamps

      t.index %i[event_id log_identity], unique: true, name: "index_tlog_deliveries_on_event_log"
      t.index %i[phase next_retry_at]
      t.index :signed_event_envelope_id
      t.index :completion_observation_id
      t.check_constraint <<~SQL.squish, name: "tlog_deliveries_phase"
        phase IN (
          'awaiting_envelope',
          'ready_to_submit',
          'submitting',
          'reconciling',
          'completed',
          'quarantined'
        )
      SQL
      t.check_constraint "signing_attempt_count >= 0",
        name: "tlog_deliveries_signing_attempts_non_negative"
      t.check_constraint "submission_attempt_count >= 0",
        name: "tlog_deliveries_submission_attempts_non_negative"
      t.check_constraint "reconciliation_attempt_count >= 0",
        name: "tlog_deliveries_reconciliation_attempts_non_negative"
      t.check_constraint <<~SQL.squish, name: "tlog_deliveries_last_error_phase"
        last_error_phase IS NULL OR last_error_phase IN (
          'signing',
          'submission',
          'response_verification',
          'reconciliation',
          'invariant'
        )
      SQL
    end
  end

  def create_inclusion_observations
    # Immutable records intentionally have no mutable timestamp columns.
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :transparency_log_inclusion_observations, id: :uuid do |t|
      t.uuid :delivery_id, null: false
      t.uuid :signed_event_envelope_id, null: false
      t.string :log_identity, null: false, limit: 255
      t.bigint :log_index, null: false
      t.string :observed_via, null: false, limit: 64
      t.datetime :observed_at, null: false
      t.binary :rekor_response
      t.binary :rekor_response_sha256
      t.binary :entry_bundle, null: false
      t.binary :entry_bundle_sha256, null: false
      t.binary :checkpoint, null: false
      t.binary :checkpoint_sha256, null: false
      t.binary :leaf_hash, null: false
      t.binary :root_hash, null: false
      t.binary :proof_hashes, null: false, array: true, default: []
      t.bigint :tree_size, null: false
      t.string :verification_policy_id, null: false, limit: 255
      t.datetime :verified_at, null: false

      t.index :delivery_id
      t.index %i[signed_event_envelope_id log_identity log_index],
        unique: true,
        name: "index_tlog_observations_on_envelope_log_index"
      t.check_constraint "observed_via IN ('submission_201', 'duplicate_409_reconciliation')",
        name: "tlog_observations_observed_via"
      t.check_constraint "log_index >= 0", name: "tlog_observations_log_index_non_negative"
      t.check_constraint "tree_size > 0", name: "tlog_observations_tree_size_positive"
      t.check_constraint "log_index < tree_size", name: "tlog_observations_index_within_tree"
      t.check_constraint "(rekor_response IS NULL) = (rekor_response_sha256 IS NULL)",
        name: "tlog_observations_response_pair"
      t.check_constraint <<~SQL.squish, name: "tlog_observations_response_source"
        (observed_via = 'submission_201' AND rekor_response IS NOT NULL) OR
        (observed_via = 'duplicate_409_reconciliation' AND rekor_response IS NULL)
      SQL
      t.check_constraint "rekor_response_sha256 IS NULL OR octet_length(rekor_response_sha256) = 32",
        name: "tlog_observations_rekor_response_digest_length"
      t.check_constraint "octet_length(entry_bundle_sha256) = 32",
        name: "tlog_observations_entry_digest_length"
      t.check_constraint "octet_length(checkpoint_sha256) = 32",
        name: "tlog_observations_checkpoint_digest_length"
      t.check_constraint "octet_length(leaf_hash) = 32", name: "tlog_observations_leaf_hash_length"
      t.check_constraint "octet_length(root_hash) = 32", name: "tlog_observations_root_hash_length"
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end

  def add_foreign_keys
    add_foreign_key :transparency_log_signed_event_envelopes,
      :transparency_log_events,
      column: :event_id,
      primary_key: :event_uuid,
      validate: false
    add_foreign_key :transparency_log_signed_event_envelopes,
      :transparency_log_signed_event_envelopes,
      column: :supersedes_envelope_id,
      validate: false
    add_foreign_key :transparency_log_deliveries,
      :transparency_log_events,
      column: :event_id,
      primary_key: :event_uuid,
      validate: false
    add_foreign_key :transparency_log_deliveries,
      :transparency_log_signed_event_envelopes,
      column: :signed_event_envelope_id,
      validate: false
    add_foreign_key :transparency_log_inclusion_observations,
      :transparency_log_deliveries,
      column: :delivery_id,
      validate: false
    add_foreign_key :transparency_log_inclusion_observations,
      :transparency_log_signed_event_envelopes,
      column: :signed_event_envelope_id,
      validate: false
    add_foreign_key :transparency_log_deliveries,
      :transparency_log_inclusion_observations,
      column: :completion_observation_id,
      validate: false
  end
end
