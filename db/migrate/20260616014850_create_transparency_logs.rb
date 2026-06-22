# frozen_string_literal: true

class CreateTransparencyLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :transparency_logs do |t|
      t.string :event_type
      t.jsonb :body
      t.jsonb :response

      t.timestamps
    end
  end
end
