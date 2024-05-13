class UpdateDefaultCohortForEhco < ActiveRecord::Migration[6.1]
  def change
    ehco_course = Course.where(identifier: "npq-early-headship-coaching-offer").first

    ehco_course&.update!(default_cohort: 2022)
  end
end
