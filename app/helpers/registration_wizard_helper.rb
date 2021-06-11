module RegistrationWizardHelper
  def registration_wizard_form_url(form)
    if form.changing_answer?
      registration_wizard_update_change_path
    else
      registration_wizard_update_path
    end
  end
end
