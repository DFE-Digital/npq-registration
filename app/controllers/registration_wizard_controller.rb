class RegistrationWizardController < ApplicationController
  def show
    @wizard = RegistrationWizard.new(current_step: params[:step].underscore)
    @form = @wizard.form.new

    render @wizard.current_step
  end

  def update
    @wizard = RegistrationWizard.new(current_step: params[:step].underscore)
    @form = @wizard.form.new(wizard_params)

    if @form.valid?
      # handle update
      # if success redirect
    else
      render @wizard.current_step
    end
  end

private

  def wizard_params
    params.require(:registration_wizard).permit(can_share_choices: [])
  end
end
