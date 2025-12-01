module AdminHelper
  def format_address(school)
    keys = %i[address_1 address_2 address_3 town county postcode]
    parts = keys.map { |k| school[k] }.compact_blank

    return if parts.blank?

    safe_join(parts, tag.br)
  end

  def admin_navigation_structure
    @admin_navigation_structure ||= NpqSeparation::NavigationStructures::AdminNavigationStructure.new(current_admin)
  end

  def admin_service_navigation_items
    return [] unless current_admin

    [
      *admin_navigation_structure.service_navigation_items,
      {
        href: sign_out_user_path,
        text: "Sign out",
        classes: "ml-auto",
      },
    ]
  end

  def review_status_tag(review_status)
    case review_status
    when "Needs review"
      govuk_tag(text: "Needs review", colour: "blue")
    when "Awaiting information"
      govuk_tag(text: "Awaiting information", colour: "yellow")
    when "Re-register", "Decision made"
      govuk_tag(text: review_status, colour: "grey")
    else
      review_status.presence
    end
  end
end
