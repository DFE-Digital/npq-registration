module API
  class QualificationsSerializer
    def self.render(participant_outcomes, root:, trn:)
      qualifications = participant_outcomes.map do |participant_outcome|
        {
          award_date: participant_outcome.completion_date,
          npq_type: participant_outcome.course.short_code, # TODO: check for courses with null short_code
        }
      end
      {
        root.to_sym => {
          trn:,
          qualifications:,
        },
      }.to_json
    end
  end
end
