module Milestones
  class Destroy
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :milestone_id, :integer

    validates :milestone_id, presence: true

    def destroy!
      milestone = Milestone.find(milestone_id)

      ActiveRecord::Base.transaction do
        milestone.milestone_statements.destroy_all
        milestone.destroy!
      end
    end
  end
end
