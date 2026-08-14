# frozen_string_literal: true

module TransparencyLog::ImmutableRecord
  extend ActiveSupport::Concern

  included do
    before_update :reject_update
    before_destroy :reject_destruction
  end

  private

  def reject_update
    errors.add(:base, immutable_record_error)
    throw :abort
  end

  def reject_destruction
    errors.add(:base, immutable_record_error)
    throw :abort
  end

  def immutable_record_error
    record_type = model_name.name.delete_prefix("TransparencyLog").underscore.humanize.downcase.pluralize
    "#{record_type} are immutable"
  end
end
