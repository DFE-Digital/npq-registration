module ApplicationHelper
  include Pagy::Frontend

  def application_count_based_account_url
    current_user.applications.size == 1 ? accounts_user_registration_path(current_user.applications.first) : account_path
  end

  def npq_registration_link
    if signed_in?
      if Feature.trn_required? && current_user.trn.blank?
        registration_wizard_show_path(:teacher_reference_number)
      else
        registration_wizard_show_path(:course_start_date)
      end
    else
      "/"
    end
  end

  def boolean_red_green_tag(bool, text = nil)
    text ||= bool ? "YES" : "NO"
    colour = bool ? "green" : "red"

    content_tag(:strong, text, class: "govuk-tag govuk-tag--#{colour}")
  end

  def boolean_tag(bool)
    bool ? "Yes" : "No"
  end

  def pagy_govuk_nav(pagy)
    render "pagy/paginator", pagy:
  end

  def show_tracking_pixels?
    cookies["consented-to-cookies"] == "accept"
  end

  def accepted?(application)
    application.lead_provider_approval_status&.capitalize == "Accepted"
  end

  def pending?(application)
    application.lead_provider_approval_status&.capitalize == "Pending"
  end

  def rejected?(application)
    application.lead_provider_approval_status&.capitalize == "Rejected"
  end

  def application_course_start_date
    "April 2024" # Currently we are showing hard coded value for Course start date, will automate this process once we have our exact tenures.
  end

  def show_otp_code_in_ui(current_env, admin)
    return unless current_env.in?(%w[development review staging])

    tag.p("OTP code: #{admin.otp_hash}")
  end
end
