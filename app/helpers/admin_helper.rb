module AdminHelper
  def format_cohort(cohort)
    start_year = cohort.start_year
    end_year = start_year.next - 2000

    "#{start_year}/#{end_year}"
  end

  def format_address(school)
    keys = %i[address_1 address_2 address_3 town county postcode]
    parts = keys.map { |k| school[k] }.compact_blank

    return if parts.blank?

    safe_join(parts, tag.br)
  end

  def admin_navigation_structure
    @admin_navigation_structure ||= NpqSeparation::NavigationStructures::AdminNavigationStructure.new
  end

  def display_feature_flag_user(serialized_actor)
    # I am getting a weird string like that: "User;0fb4a014..."
    # I know it is user identifier. The bit after ; is some kind of user identifier
    # I want to extract the bit after the ;
    user_uid = serialized_actor.split(";").last
    # I want to find user based on the ID (the bit after ;)
    user = User.find_by("feature_flag_id" => user_uid)
    # I display the user name
    user.full_name
  end

end
