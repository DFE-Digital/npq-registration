# frozen_string_literal: true

module NpqSeparation
  module Admin
    module Applications
      class NotesController < NpqSeparation::AdminController
        before_action :set_application

        def edit; end

        def update
          if @application.update(notes_params)
            flash[:success] = "Notes updated."
            redirect_to npq_separation_admin_application_review_path(@application)
          else
            render :edit
          end
        end

      private

        def notes_params
          params.require(:application).permit(:notes)
        end

        def set_application
          @application = Application.find(params[:id])
        end
      end
    end
  end
end
