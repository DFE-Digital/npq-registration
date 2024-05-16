class SetLeadProviderNames < ActiveRecord::Migration[7.1]
  def up
    LeadProvider.where(name: "Best Practice Network (home of Outstanding Leaders Partnership)").update_all(name: "Best Practice Network")
    LeadProvider.where(name: "UCL Institute of Education").update_all(name: "University College London (UCL) Institute of Education")
    LeadProvider.where(name: "Leadership Learning South East (LLSE)").update_all(name: "LLSE")
  end

  def down
    LeadProvider.where(name: "Best Practice Network").update_all(name: "Best Practice Network (home of Outstanding Leaders Partnership)")
    LeadProvider.where(name: "University College London (UCL) Institute of Education").update_all(name: "UCL Institute of Education")
    LeadProvider.where(name: "LLSE").update_all(name: "Leadership Learning South East (LLSE)")
  end
end
