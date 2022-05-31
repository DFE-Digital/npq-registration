class RegistrationWizardController < ApplicationController
  def show
    @wizard = RegistrationWizard.new(current_step: params[:step].underscore,
                                     store: store,
                                     request: request)

    @form = @wizard.form
    @form.flag_as_changing_answer if params[:changing_answer] == "1"

    @wizard.before_render

    return redirect_to root_path unless @form.requirements_met?

    render @wizard.current_step

    @wizard.after_render
  end

  def update
    @wizard = RegistrationWizard.new(current_step: params[:step].underscore,
                                     store: store,
                                     params: wizard_params,
                                     request: request)
    @form = @wizard.form
    @form.flag_as_changing_answer if params[:changing_answer] == "1"

    if @form.valid?
      if @form.changing_answer? && @form.next_step != :check_answers
        redirect_to registration_wizard_show_change_path(@wizard.next_step_path)
      else
        redirect_to registration_wizard_show_path(@wizard.next_step_path)
      end

      @wizard.save!
    else
      render @wizard.current_step
    end
  end

private

  def store
    session["registration_store"] ||= {}
  end

  def wizard_params
    return {} if Services::Feature.registration_closed?

    params.fetch(:registration_wizard, {}).permit(RegistrationWizard.permitted_params_for_step(params[:step].underscore))
  end
end
