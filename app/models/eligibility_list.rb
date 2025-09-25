class EligibilityList < ApplicationRecord
  enum eligibility_list_type: {
    pp50_school: "pp50_school",
    pp50_further_education: "pp50_further_education",
    childminder: "childminder",
    disadvantaged_early_years_school: "disadvantaged_early_years_school",
    local_authority_nursery: "local_authority_nursery",
    rise_school: "rise_school",
  }

  def self.pp50_school?(urn)
    exists?(eligibility_list_type: eligibility_list_types[:pp50_school], identifier: urn)
  end

  def self.pp50_further_education?(ukprn)
    exists?(eligibility_list_type: eligibility_list_types[:pp50_further_education], identifier: ukprn)
  end

  def self.childminder?(urn)
    exists?(eligibility_list_type: eligibility_list_types[:childminder], identifier: urn)
  end

  def self.disadvantaged_early_years_school?(urn)
    exists?(eligibility_list_type: eligibility_list_types[:disadvantaged_early_years_school], identifier: urn)
  end

  def self.local_authority_nursery?(urn)
    exists?(eligibility_list_type: eligibility_list_types[:local_authority_nursery], identifier: urn)
  end

  def self.rise_school?(urn)
    exists?(eligibility_list_type: eligibility_list_types[:rise_school], identifier: urn)
  end
end
