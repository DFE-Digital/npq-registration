class UpdateDefaultCohortForEhco < ActiveRecord::Migration[6.1]
  def change
    ehco_course = if ActiveRecord::Base.connection.column_exists?(:courses, :identifier)
                    Course.where(identifier: "npq-early-headship-coaching-offer").first
                  else
                    Course.where(name: "Early Headship Coaching Offer").first
                  end

    ehco_course&.update!(default_cohort: 2022)
  end
end
