module RegistrationWizardHelper
  def registration_wizard_form_url(form)
    if Rails.configuration.x.dfe_wizard
      registration_wizard_show_path
    elsif form.changing_answer?
      registration_wizard_update_change_path
    else
      registration_wizard_update_path
    end
  end

  def registration_wizard_back_link(wizard)
    if Rails.configuration.x.dfe_wizard
      wizard.previous_step_path(fallback: root_path)
    else
      registration_wizard_show_url(wizard.previous_step_path)
    end
  end

  def registration_wizard_next_link(wizard)
    if Rails.configuration.x.dfe_wizard
      wizard.next_step_path
    else
      registration_wizard_show_path(wizard.next_step_path)
    end
  end
end
