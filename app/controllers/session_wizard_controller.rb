class SessionWizardController < PublicPagesController
  def show
    @wizard = SessionWizard.new(current_step: session_step, store:, session:)
    @form = @wizard.form

    render @wizard.current_step
  end

  def update
    @wizard = SessionWizard.new(current_step: session_step,
                                store:,
                                params: wizard_params,
                                session:)
    @form = @wizard.form

    if @form.valid?
      @wizard.save!

      if @wizard.finished?
        admin_id = @form.admin.id
        reset_session
        session["admin_id"] = admin_id
        session["admin_sign_in_at"] = Time.zone.now.utc
        redirect_to admin_path
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
    params.fetch(:session_wizard, {})
          .permit(SessionWizard.permitted_params_for_step(session_step))
  end

  def session_step
    params[:step].underscore
  end
end
