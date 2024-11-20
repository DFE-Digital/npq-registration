# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class ChangeTrainingStatusesController < NpqSeparation::AdminController
        before_action :set_application, :set_training_status

        def new; end

        def create
          @change_training_status.assign_attributes(training_status_params)

          if @change_training_status.change_training_status
            redirect_to npq_separation_admin_application_path(@application)
          else
            render :new, status: :unprocessable_entity
          end
        end

      private

        def set_application
          @application = Application.find(params[:id])
        end

        def set_training_status
          @change_training_status =
            ::Applications::ChangeTrainingStatus.new(application: @application)
        end

        def training_status_params
          params.fetch(:change_training_status, {}).permit(:training_status, :reason)
        end
      end
    end
  end
end
