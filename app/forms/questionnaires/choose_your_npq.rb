module Questionnaires
  class ChooseYourNpq < Base
    QUESTION_NAME = :course_identifier

    attribute QUESTION_NAME

    validates QUESTION_NAME, presence: true
    validate :validate_course_exists

    delegate :inside_catchment?,
             :cohort_funded?,
             :check_funding?,
             to: :query_store

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :course_identifier,
          options:,
          style_options: { legend: { size: "m", tag: "h2" } },
        ),
      ]
    end

    def options
      divider_index = courses.length - 1 # Place the "Or" divider before the last course
      courses
        .each_with_index.map do |course, index|
          build_option_struct(
            value: course.identifier,
            link_errors: index.zero?,
            divider: divider_index == index,
            label: I18n.t("course.name.#{course.identifier}", default: course.name),
            hint: course.description,
          )
        end
    end

    def after_save
      # TODO: move this to correct step
      # wizard.store["funding_eligiblity_status_code"] = funding_eligibility_calculator.funding_eligiblity_status_code
    end

    def next_step
      :funding_history
    end

    def previous_step
      if cohort_funded?
        if check_funding?
          if inside_catchment?
            :teacher_catchment
          else
            :ineligible_for_funding
          end
        else
          :check_funding
        end
      else
        :course_start_date
      end
    end

    def course
      courses.find_by(identifier: course_identifier)
    end

  private

    def courses
      Course.where(display: true).order(:position)
    end

    def previous_course
      wizard.query_store.course
    end

    def validate_course_exists
      if course.blank?
        errors.add(:course_identifier, :invalid)
      end
    end
  end
end
