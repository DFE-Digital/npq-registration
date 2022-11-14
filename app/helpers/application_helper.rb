module ApplicationHelper
  include Pagy::Frontend

  def boolean_red_green_tag(bool)
    if bool
      '<strong class="govuk-tag govuk-tag--green">YES</strong>'
    else
      '<strong class="govuk-tag govuk-tag--red">NO</strong>'
    end.html_safe
  end

  def pagy_govuk_nav(pagy)
    render "pagy/paginator", pagy:
  end

  def show_tracking_pixels?
    cookies["consented-to-cookies"] == "accept"
  end
end
