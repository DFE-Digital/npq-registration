module CourseGroups
  class Support
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :course_group
    attribute :cohort

    delegate :schedules, to: :course_group

    def schedule
      # Default
      schedules.find_by!(cohort:, identifier: "npq-aso-december")
    end
  end
end
