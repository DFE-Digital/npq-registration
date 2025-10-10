module NpqSeparation
  module Admin
    module Applications
      class OutcomeController < NpqSeparation::AdminController
        before_action :set_application

        def show
          @outcomes = @application.declarations.flat_map(&:participant_outcomes)
        end

      private

        def set_application
          @application = Application.includes(:declarations).find(params[:id])
        end
      end
    end
  end
end
