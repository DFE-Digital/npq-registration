class SessionWizardController < ApplicationController
  def show
    @wizard = SessionWizard.new(current_step: params[:step].underscore,
                                store:,
                                session:)
    @form = @wizard.form

    render @wizard.current_step
  end

  def update
    @wizard = SessionWizard.new(current_step: params[:step].underscore,
                                store:,
                                params: wizard_params,
                                session:)
    @form = @wizard.form

    if @form.valid?
      @wizard.save!

      if @wizard.finished?
        user_id = @form.user.id
        reset_session
        session["user_id"] = user_id
        redirect_to account_path
      else
        redirect_to session_wizard_show_path(@wizard.next_step_path)
      end
    else
      render @wizard.current_step
    end
  end

private

  def store
    session["session_store"] ||= {}
  end

  def wizard_params
    params.fetch(:session_wizard, {}).permit(SessionWizard.permitted_params_for_step(params[:step].underscore))
  end
end
