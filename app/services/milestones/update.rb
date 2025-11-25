module Milestones
  class Update
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :milestone_id, :integer
    attribute :statement_date, :date

    validates :milestone_id, presence: true
    validates :statement_date, presence: true

    def update!
      milestone = Milestone.find(milestone_id)

      ActiveRecord::Base.transaction do
        milestone.milestone_statements.destroy_all
        LeadProvider.find_each do |lead_provider|
          statement = lead_provider
            .statements
            .with_output_fee
            .find_by(month: statement_date.month, year: statement_date.year)
          milestone.milestone_statements.find_or_create_by!(statement: statement)
        end
      end
    end
  end
end
