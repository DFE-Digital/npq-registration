module API
  module V1
    class QualificationsController < BaseController
      def show
        trn = params[:trn]
        results = ParticipantOutcome
          .includes(declaration: [application: [:course]])
          .where(state: "passed")
          .joins(declaration: [application: :user])
          .where("users.trn": trn)
        qualifications = results.map do |result|
          {
            award_date: result.completion_date,
            npq_type: result.course.short_code,
          }
        end
        render json: {
          data: {
            trn:,
            qualifications:,
          },
        }
      end
    end
  end
end
