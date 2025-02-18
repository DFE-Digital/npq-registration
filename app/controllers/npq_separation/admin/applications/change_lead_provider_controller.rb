# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class ChangeLeadProviderController < NpqSeparation::AdminController
        before_action :set_application, :set_change_lead_provider

        def create
          @change_lead_provider.assign_attributes(lead_provider_params)

          if @change_lead_provider.change_lead_provider
            redirect_to npq_separation_admin_application_path(@application)
          else
            render :show, status: :unprocessable_entity
          end
        end

      private

        def set_application
          @application = Application.find(params[:id])
        end

        def set_change_lead_provider
          @change_lead_provider =
            ::Applications::ChangeLeadProvider.new(application: @application)
        end

        def lead_provider_params
          params.fetch(:applications_change_lead_provider, {}).permit(:lead_provider_id)
        end
      end
    end
  end
end
