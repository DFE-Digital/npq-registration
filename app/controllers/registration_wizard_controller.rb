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

      redirect_to registration_wizard_show_path(@wizard.next_step)
    else
      render @wizard.current_step
    end
  end

private

  def store
    session[:registration_store] ||= {}
  end

  def wizard_params
    params.require(:registration_wizard).permit(RegistrationWizard.permitted_params_for_step(params[:step].underscore))
  end
end
