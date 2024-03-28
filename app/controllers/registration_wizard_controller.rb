class RegistrationWizardController < ApplicationController
  before_action :registration_closed
  before_action :set_wizard
  before_action :set_form
  before_action :check_end_of_journey, only: %i[update]

  def show
    @form.flag_as_changing_answer if params[:changing_answer] == "1"

    @wizard.before_render

    return redirect_to registration_wizard_show_path(@wizard.next_step_path) if @wizard.skip_step?
    return redirect_to root_path unless @form.requirements_met?

    render @wizard.current_step

    @wizard.after_render
  end

  def update
    @form.flag_as_changing_answer if params[:changing_answer] == "1"

    if @form.valid?
      if @form.redirect_to_change_path?
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

  def set_wizard
    @wizard = RegistrationWizard.new(current_step: params[:step].underscore, store:, params: wizard_params, request:, current_user:)
  end

  def set_form
    @form = @wizard.form
  end

  def check_end_of_journey
    if @form.valid? && @form.last_step?
      @wizard.save!
      redirect_to accounts_user_registration_path(current_user.applications.last, success: true)
    end
  end

  def registration_closed
    return if request.path == registration_wizard_show_path(:closed)

    if Feature.registration_closed?(current_user)
      if params[:step] == "start"
        redirect_to registration_closed_path
      else
        redirect_to registration_wizard_show_path(:closed)
      end
    end
  end

  def store
    session["registration_store"] ||= {}
  end

  def wizard_params
    return {} if Feature.registration_closed?(current_user)

    params.fetch(:registration_wizard, {}).permit(RegistrationWizard.permitted_params_for_step(params[:step].underscore))
  end
end
