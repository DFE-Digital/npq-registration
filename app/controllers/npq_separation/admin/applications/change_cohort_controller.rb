# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class ChangeCohortController < NpqSeparation::AdminController
        before_action :set_application, :set_change_cohort

        def create
          @change_cohort.assign_attributes(cohort_params)

          if @change_cohort.change_cohort
            redirect_to npq_separation_admin_application_path(@application)
          else
            render :show, status: :unprocessable_entity
          end
        end

      private

        def set_application
          @application = Application.find(params[:id])
        end

        def set_change_cohort
          @change_cohort =
            ::Applications::ChangeCohort.new(application: @application)
        end

        def cohort_params
          params.fetch(:applications_change_cohort, {}).permit(:cohort_id)
        end
      end
    end
  end
end
