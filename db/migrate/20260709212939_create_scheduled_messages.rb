class CreateScheduledMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :scheduled_messages do |t|
      t.references :account, null: false
      t.references :conversation, null: false
      t.references :sender, null: false
      t.text :content, null: false
      t.boolean :private, null: false, default: false
      t.datetime :scheduled_at, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :scheduled_messages, :scheduled_at
  end
end
