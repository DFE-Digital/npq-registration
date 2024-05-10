class AddReplacedByToCourse < ActiveRecord::Migration[7.1]
  def change
    add_column :courses, :replaced_by_course_id, :integer, null: true

    add_foreign_key :courses, :courses, column: :replaced_by_course_id, primary_key: :id, on_delete: :nullify

    # npq-additional-support-offer was replaced by npq-early-headship-coaching-offer
    npq_additional_support_offer = Course.find_by!(identifier: "npq-additional-support-offer")
    npq_early_headship_coaching_offer = Course.find_by!(identifier: "npq-early-headship-coaching-offer")

    npq_additional_support_offer.update!(replaced_by: npq_early_headship_coaching_offer)
  end
end
