class UpdateDefaultCohortForEhco < ActiveRecord::Migration[6.1]
  def change
    ehco_course = Course.find_by_code(code: :EHCO)

    ehco_course&.update!(default_cohort: 2022)
  end
end
