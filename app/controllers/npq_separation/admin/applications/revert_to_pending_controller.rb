module NpqSeparation
  module Admin
    module Applications
      class RevertToPendingController < NpqSeparation::AdminController
        before_action :set_application
        before_action :set_revert_to_pending_form

        def new; end

        def create
          if @revert_to_pending_form.revert
            redirect_to npq_separation_admin_application_path(@application)
          else
            render :new, status: :unprocessable_entity
          end
        end

      private

        def set_revert_to_pending_form
          @revert_to_pending_form = ::Applications::RevertToPending
            .new(@application, form_params)
        end

        def form_params
          params.fetch(:applications_revert_to_pending, {})
                .permit(:change_status_to_pending)
        end

        def set_application
          @application = Application.find(params[:id])
        end
      end
    end
  end
end
