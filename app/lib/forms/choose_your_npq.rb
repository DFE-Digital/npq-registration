module Forms
  class ChooseYourNpq < Base
    include Helpers::Institution

    attr_accessor :course_id

    validates :course_id, presence: true
    validate :validate_course_exists

    def self.permitted_params
      %i[
        course_id
      ]
    end

    def next_step
      if changing_answer?
        if no_answers_will_change?
          :check_answers
        elsif course.ehco?
          :about_ehco
        elsif previously_eligible_for_funding? && !eligible_for_funding?
          if ineligible_institution_type?
            :your_work
          else
            :ineligible_for_funding
          end
        else
          :check_answers
        end
      elsif course.ehco?
        :about_ehco
      elsif wizard.query_store.works_in_childcare? || wizard.query_store.works_in_school?
        if eligible_for_funding?
          :possible_funding
        else
          :ineligible_for_funding
        end
      elsif ineligible_institution_type?
        :your_work
      else
        :ineligible_for_funding
      end
    end

    def previous_step
      if query_store.inside_catchment? && query_store.works_in_school?
        :choose_school
      elsif query_store.inside_catchment? && query_store.works_in_childcare?
        if query_store.works_in_nursery? && query_store.works_in_public_childcare_provider?
          :choose_childcare_provider
        elsif query_store.has_ofsted_urn?
          :choose_private_childcare_provider
        else
          :have_ofsted_urn
        end
      else
        :work_in_childcare
      end
    end

    def options
      courses.each_with_index.map do |course, index|
        OpenStruct.new(value: course.id,
                       text: course.name,
                       link_errors: index.zero?,
                       hint: course.description)
      end
    end

    def course
      courses.find_by(id: course_id)
    end

  private

    def courses
      Course.where(display: true).order(:position)
    end

    def previous_course
      Course.find_by(id: wizard.store["course_id"])
    end

    def previously_eligible_for_funding?
      Services::FundingEligibility.new(
        course: previous_course,
        institution: institution,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
      ).funded?
    end

    def funding_eligibility_calculator
      @funding_eligibility_calculator ||= Services::FundingEligibility.new(
        course: course,
        institution: institution,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
      )
    end

    def eligible_for_funding?
      funding_eligibility_calculator.funded?
    end

    delegate :ineligible_institution_type?, to: :funding_eligibility_calculator
    delegate :new_headteacher?, :inside_catchment?, to: :query_store

    def validate_course_exists
      if course.blank?
        errors.add(:course_id, :invalid)
      end
    end
  end
end
