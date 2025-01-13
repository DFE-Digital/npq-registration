module API
  module TeacherRecordService
    class QualificationsController < BaseController
      def show
        participant_outcomes = participant_outcome_query

        render json: to_json(participant_outcomes)
      end

    private

      def trn
        params[:trn]
      end

      def participant_outcome_query
        Qualifications::Query.new.qualifications(trn:)
      end

      def to_json(participant_outcomes)
        QualificationsSerializer.render(trn, root: "data", participant_outcomes:)
      end

      def api_token_scope
        APIToken.scopes[:teacher_record_service]
      end
    end
  end
end
