class RegistrationWizardController < ApplicationController
  def show
    @wizard = RegistrationWizard.new(current_step: params[:step].underscore, store: store)
    @form = @wizard.form

    render @wizard.current_step
  end

  def update
    @wizard = RegistrationWizard.new(current_step: params[:step].underscore,
                                     store: store,
                                     params: wizard_params)
    @form = @wizard.form

    if @form.valid?
      @wizard.save!

      # handle update
      # if success redirect
    else
      render @wizard.current_step
    end
  end

private

  def store
    session[:registration_store] ||= {}
  end

  def wizard_params
    params.require(:registration_wizard).permit(:can_share_choices)
  end
end
