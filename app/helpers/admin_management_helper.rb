module AdminManagementHelper
  def admin_type_cell_contents(admin)
    if admin.super_admin?
      govuk_tag(text: t(".admin_type.super_admin"), colour: "blue")
    else
      govuk_tag(text: t(".admin_type.admin"), colour: "green")
    end
  end

  def super_admin?
    current_admin.super_admin?
  end

  def remove_as_admin_cell_contents(user)
    govuk_button_link_to(t(".buttons.delete"), admin_admin_path(user), method: :delete, warning: true)
  end

  def elevate_to_super_admin_cell_contents(user)
    return "" if user.super_admin?

    govuk_link_to(t(".buttons.elevate"), admin_super_admin_path(user), method: :patch)
  end
end
