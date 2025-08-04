module Helpers
  module BulkOperations
    def applications_file
      @applications_file ||= tempfile_with_bom(Application.all.pluck(:ecf_id).join("\n"))
    end

    def empty_file
      @empty_file ||= Tempfile.new
    end

    def wrong_format_file
      @wrong_format_file ||= tempfile_with_bom("one,two\nthree,four\n")
    end

    def declarations_file
      @declarations_file ||= begin
        cohort = Cohort.current
        course = create(:course, :senior_leadership)

        lead_provider = create(:lead_provider)
        delivery_partner = create(:delivery_partner)
        schedule = create(:schedule, cohort:, course_group: course.course_group, allowed_declaration_types: %w[started completed])

        # Create required contracts and partnerships
        statement = create(:statement, cohort:, lead_provider:)
        create(:contract, statement:, course:)
        create(:delivery_partnership, cohort:, delivery_partner:, lead_provider:)

        participant1 = create(:user)
        participant2 = create(:user)

        create(:application, :accepted, user: participant1, cohort:, course:, lead_provider:, schedule:)
        create(:application, :accepted, user: participant2, cohort:, course:, lead_provider:, schedule:)

        tempfile_with_bom <<~CSV
          participant_id,declaration_type,declaration_date,course_identifier,delivery_partner_id,lead_provider_name,has_passed
          #{participant1.ecf_id},started,#{schedule.applies_from.rfc3339},#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
          #{participant2.ecf_id},completed,#{(schedule.applies_from + 1.day).rfc3339},#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",TRUE
        CSV
      end
    end
  end
end
