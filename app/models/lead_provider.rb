class LeadProvider < ApplicationRecord
  # name => ecf_id
  NPQEYL_AND_NPQLL_LEAD_PROVIDERS = {
    "Ambition Institute" => "9e35e998-c63b-4136-89c4-e9e18ddde0ea",
    "Education Development Trust" => "21e61f53-9b34-4384-a8f5-d8224dbf946d",
    "School-Led Network" => "bc5e4e37-1d64-4149-a06b-ad10d3c55fd0",
    "Teacher Development Trust" => "30fd937e-b93c-4f81-8fff-3c27544193f1",
    "Teach First" => "a02ae582-f939-462f-90bc-cebf20fa8473",
    "UCL Institute of Education" => "ef687b3d-c1c0-4566-a295-16d6fa5d0fa7",
  }.freeze

  scope :alphabetical, -> { order(name: :asc) }

  def self.for(course:)
    case course.name
    when Course::COURSE_NAMES[:NPQEYL], Course::COURSE_NAMES[:NPQLL]
      npqeyl_and_npqll_providers
    else
      all
    end
  end

  def self.npqeyl_and_npqll_providers
    where(ecf_id: NPQEYL_AND_NPQLL_LEAD_PROVIDERS.values)
  end
end
