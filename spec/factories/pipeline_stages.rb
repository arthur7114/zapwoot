FactoryBot.define do
  factory :pipeline_stage do
    account
    sequence(:title) { |n| "Stage #{n}" }
    color { '#009CE0' }
    sequence(:position) { |n| n }
  end
end
