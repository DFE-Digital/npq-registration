# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class ChangeFundingEligibilitiesController < NpqSeparation::AdminController
        before_action :set_application

        def new
          @funding_eligibility = ::Applications::ChangeFundingEligibility.new(application: @application, eligible_for_funding: @application.eligible_for_funding)
        end

        def create
          @funding_eligibility = ::Applications::ChangeFundingEligibility.new(application: @application)
          @funding_eligibility.assign_attributes(funding_eligibility_params)

          if @funding_eligibility.change_funding_eligibility
            if @application.previous_changes["eligible_for_funding"]
              flash[:success] = "Funding eligibility has been changed to ‘#{@application.eligible_for_funding ? 'Yes' : 'No'}’"
            end
            redirect_to npq_separation_admin_application_path(@application)
          else
            render :new, status: :unprocessable_entity
          end
        end

      private

        def set_application
          @application = Application.find(params[:id])
        end

        def funding_eligibility_params
          params.fetch(:applications_change_funding_eligibility, {}).permit(:eligible_for_funding)
        end
      end
    end
  end
end
