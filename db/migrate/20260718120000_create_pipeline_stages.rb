class CreatePipelineStages < ActiveRecord::Migration[7.1]
  def change
    create_table :pipeline_stages do |t|
      t.references :account, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :position, null: false, default: 0
      t.string :color

      t.timestamps
    end
    add_index :pipeline_stages, [:account_id, :position]

    add_column :conversations, :pipeline_stage_id, :bigint
  end
end
