# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class TrainingStatusesController < NpqSeparation::AdminController
        before_action :set_application, :set_training_status

        def edit; end

        def update
          @training_status.assign_attributes(training_status_params)

          if @training_status.save
            redirect_to npq_separation_admin_application_path(@application), status: :see_other
          else
            render :edit, status: :unprocessable_entity
          end
        end

      private

        def set_application
          @application = Application.find(params[:id])
        end

        def set_training_status
          @training_status = ::Applications::UpdateTrainingStatus.new(@application)
        end

        def training_status_params
          params.require(:update_training_status).permit(:training_status)
        end
      end
    end
  end
end
