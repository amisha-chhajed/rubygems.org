# frozen_string_literal: true

class ValidateTransparencyLogPersistenceForeignKeys < ActiveRecord::Migration[8.1]
  def up
    validate_foreign_key :transparency_log_signed_event_envelopes,
      :transparency_log_events,
      column: :event_id
    validate_foreign_key :transparency_log_signed_event_envelopes,
      :transparency_log_signed_event_envelopes,
      column: :supersedes_envelope_id
    validate_foreign_key :transparency_log_deliveries,
      :transparency_log_events,
      column: :event_id
    validate_foreign_key :transparency_log_deliveries,
      :transparency_log_signed_event_envelopes,
      column: :signed_event_envelope_id
    validate_foreign_key :transparency_log_inclusion_observations,
      :transparency_log_deliveries,
      column: :delivery_id
    validate_foreign_key :transparency_log_inclusion_observations,
      :transparency_log_signed_event_envelopes,
      column: :signed_event_envelope_id
    validate_foreign_key :transparency_log_deliveries,
      :transparency_log_inclusion_observations,
      column: :completion_observation_id
  end

  def down = nil
end
