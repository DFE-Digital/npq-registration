class RegistrationWizardController < ApplicationController
  def show
    @wizard = RegistrationWizard.new(current_step: params[:step].underscore)

    render @wizard.current_step
  end

  def update
    # handle update
    # if success redirect
    # otherwise render
  end
end
