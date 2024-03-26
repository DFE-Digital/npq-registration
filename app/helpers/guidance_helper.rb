module GuidanceHelper
  def guidance_navigation_structure
    @guidance_navigation_structure ||= NpqSeparation::NavigationStructures::GuidanceNavigationStructure.new
  end
end
