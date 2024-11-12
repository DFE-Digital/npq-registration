class UpdateUclProviderName < ActiveRecord::Migration[7.1]
  def up
    LeadProvider.where(name: "University College London (UCL) Institute of Education").update_all(name: "UCL Institute of Education")
  end

  def down
    LeadProvider.where(name: "UCL Institute of Education").update_all(name: "University College London (UCL) Institute of Education")
  end
end
