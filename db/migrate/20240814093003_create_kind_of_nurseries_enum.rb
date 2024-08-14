class CreateKindOfNurseriesEnum < ActiveRecord::Migration[7.1]
  def change
    create_enum :kind_of_nurseries, %w[local_authority_maintained_nursery preschool_class_as_part_of_school private_nursery another_early_years_setting childminder]
  end
end
