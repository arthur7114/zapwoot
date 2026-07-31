# == Schema Information
#
# Table name: pipeline_stages
#
#  id         :bigint           not null, primary key
#  color      :string
#  position   :integer          default(0), not null
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_pipeline_stages_on_account_id               (account_id)
#  index_pipeline_stages_on_account_id_and_position  (account_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class PipelineStage < ApplicationRecord
  belongs_to :account
  has_many :conversations, dependent: :nullify

  validates :title, presence: true

  default_scope { order(:position) }
end
