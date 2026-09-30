class AddSendScheduleToCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :campaigns, :send_schedule, :jsonb, default: {}, null: false
    add_column :campaigns, :dispatch_token, :string

    create_table :campaign_recipients do |t|
      t.bigint :account_id, null: false
      t.bigint :campaign_id, null: false
      t.bigint :contact_id, null: false
      t.bigint :inbox_id, null: false
      t.bigint :message_id
      t.integer :status, default: 0, null: false
      t.text :message_content
      t.text :error_message
      t.datetime :sent_at
      t.datetime :failed_at
      t.timestamps
    end
    add_index :campaign_recipients, [:campaign_id, :contact_id], unique: true
    add_index :campaign_recipients, [:campaign_id, :status]
    add_index :campaign_recipients, [:campaign_id, :sent_at]
    add_index :campaign_recipients, :contact_id
  end
end
