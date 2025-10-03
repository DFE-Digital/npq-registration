module API
  module TeacherRecordService
    module V1
      class QualificationsController < BaseController
        def show
          render json: {
            data: {
              trn:,
              qualifications:,
            },
          }.to_json
        end

      private

        def trn
          params[:trn]
        end

        def qualifications
          Qualifications::Query.new.qualifications(trn:)
        end

        def api_token_scope
          APIToken.scopes[:teacher_record_service]
        end
      end
    end
  end
end
