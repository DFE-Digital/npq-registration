module Admin::Applications
  class OutcomeController < AdminController
    before_action :set_application

    def show
      @outcomes = ParticipantOutcome.where(declaration: @application.declarations)
    end

  private

    def set_application
      @application = Application.includes(declarations: :participant_outcomes).find(params[:id])
    end
  end
end
