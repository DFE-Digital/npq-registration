class AddFundingToCohorts < ActiveRecord::Migration[8.0]
  def up
    create_enum :cohort_funding, %w[funded capped unfunded]
    add_column :cohorts, :funding, :enum, enum_type: "cohort_funding", default: "funded", null: false

    safety_assured do
      execute <<~SQL
        UPDATE cohorts
        SET funding =
          CASE
            WHEN funding_cap = true THEN 'capped'::cohort_funding
            WHEN funding_cap = false THEN 'funded'::cohort_funding
          END
      SQL
    end
  end

  def down
    remove_column :cohorts, :funding
    drop_enum :cohort_funding
  end
end
