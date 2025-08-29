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
    text ||= bool ? "Yes" : "No"
    colour = bool ? "green" : "red"

    govuk_tag(text:, colour:)
  end

  def boolean_red_green_nil_tag(bool, text = nil)
    return "–" if bool.nil?

    boolean_red_green_tag(bool, text)
  end

  def boolean_tag(bool)
    bool ? "Yes" : "No"
  end

  def show_tracking_pixels?
    Rails.configuration.x.tracking_pixels_enabled && cookies["consented-to-cookies"] == "accept"
  end

  def accepted?(application)
    application.accepted_lead_provider_approval_status?
  end

  def pending?(application)
    application.pending_lead_provider_approval_status?
  end

  def rejected?(application)
    application.rejected_lead_provider_approval_status?
  end

  def application_course_start_date
    "autumn 2025"
  end

  def show_otp_code_in_ui(current_env, admin)
    return unless current_env.in?(%w[development review staging]) && admin.present?

    tag.p("OTP code: #{admin.otp_hash}")
  end

  def lead_provider_approval_status_badge(lead_provider_approval_status)
    return nil unless lead_provider_approval_status

    colour = {
      pending: "blue",
      accepted: "green",
      rejected: "red",
    }.fetch(lead_provider_approval_status.to_sym, "grey")

    govuk_tag(text: lead_provider_approval_status.humanize, colour:)
  end

  def sentry_javascript_tag
    dsn = Sentry.configuration.dsn.public_key
    return if dsn.blank?

    javascript_include_tag "https://js.sentry-cdn.com/#{dsn}.min.js", crossorigin: "anonymous"
  end

  def join_with_commas(*args)
    args.select(&:present?).join(", ")
  end

  def trn_verified_badge(user)
    return unless user

    if user.trn_verified == false
      govuk_tag(text: "Not verified", colour: "red")
    else
      verified_method = user.trn_auto_verified ? "automatically" : "manually"
      govuk_tag(text: "Verified", colour: "green") + " - #{verified_method}"
    end
  end
end
