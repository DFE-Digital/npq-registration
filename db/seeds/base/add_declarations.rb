# frozen_string_literal: true

helpers            = Class.new { include ActiveSupport::Testing::TimeHelpers }.new
lead_providers     = LeadProvider.alphabetical.limit(2) # it's very slow to do this for all lead providers
application_count  = 1

lead_providers.each do |lead_provider|
  Schedule.find_each do |schedule|
    schedule.courses.each do |course|
      application_count.times do
        application = FactoryBot.create(
          :application,
          :eligible_for_funded_place,
          :with_random_user,
          :with_random_work_setting,
          cohort: schedule.cohort,
          lead_provider:,
          course:,
          schedule:,
        )

        schedule.allowed_declaration_types.each.with_index do |declaration_type, i|
          declaration = nil
          date        = schedule.applies_from + (application_count * i * 2).months

          next if date.future?

          helpers.travel_to date do
            declaration = FactoryBot.create(
              :declaration,
              :submitted_or_eligible,
              application:,
              declaration_type:,
            )

            Declarations::StatementAttacher.new(declaration:).attach

            if declaration_type == "completed" && (application.id % 5).zero?
              ParticipantOutcomes::Create::STATES.reverse.each do |state|
                FactoryBot.create(:participant_outcome,
                                  declaration:,
                                  state:,
                                  completion_date: declaration.declaration_date.to_s)
                next unless state == "passed"

                user = application.user
                old_full_name = user.full_name
                user.full_name = "Kate #{old_full_name}"
                user.save!
              end
            end
          end

          # create some voided declarations
          if schedule.allowed_declaration_types.count < 4 && declaration_type == "retained-1" && declaration.statements.any?
            voidable_statement = declaration.statements.first
            helpers.travel_to voidable_statement.deadline_date + 1.month do
              Declarations::Void.new(declaration:).void
            end
          end
        end
      end

      application_count += 1
      application_count = 1 if application_count > 3
    end
  end
end
