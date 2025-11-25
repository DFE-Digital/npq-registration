module Milestones
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :schedule_id, :integer
    attribute :declaration_type, :string
    attribute :statement_date, :date

    validates :schedule_id, presence: true
    validates :declaration_type, presence: true
    validates :statement_date, presence: true

    def create!
      ActiveRecord::Base.transaction do
        schedule = Schedule.find(schedule_id)
        milestone = schedule.milestones.create!(declaration_type: declaration_type)

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
