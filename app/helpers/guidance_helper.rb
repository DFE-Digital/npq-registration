module GuidanceHelper
  def guidance_navigation_structure
    @guidance_navigation_structure ||= NavigationStructures::GuidanceNavigationStructure.new
  end
end
