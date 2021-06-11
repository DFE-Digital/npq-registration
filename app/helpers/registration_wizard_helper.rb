module RegistrationWizardHelper
  def url_for_form(form)
    if form.changing_answer?
      registration_wizard_update_change_path
    else
      registration_wizard_update_path
    end
  end
end
