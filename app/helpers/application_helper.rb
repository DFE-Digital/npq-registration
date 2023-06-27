module ApplicationHelper
  include Pagy::Frontend

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
end
