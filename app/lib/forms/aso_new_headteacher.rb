module Forms
  class AsoNewHeadteacher < Base
    VALID_ASO_NEW_HEADTEACHER_OPTIONS = %w[yes no].freeze

    include Helpers::Institution

    attr_accessor :aso_new_headteacher

    validates :aso_new_headteacher, presence: true, inclusion: { in: VALID_ASO_NEW_HEADTEACHER_OPTIONS }

    def self.permitted_params
      %i[
        aso_new_headteacher
      ]
    end

    def next_step
      case funding_eligiblity_status_code
      when :funded
        :aso_possible_funding
      when :previously_funded
        :aso_previously_funded
      else
        :aso_funding_not_available
      end
    end

    def previous_step
      :aso_headteacher
    end

    def options
      options_array.each_with_index.map do |option, index|
        OpenStruct.new(value: option[:value],
                       text: option[:text],
                       link_errors: index.zero?)
      end
    end

  private

    def course
      Course.find_by(id: wizard.store["course_id"])
    end

    def funding_eligiblity_status_code
      Services::FundingEligibility.new(
        course: course,
        institution: institution,
        inside_catchment: wizard.query_store.inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: @wizard.store["trn"],
      ).funding_eligiblity_status_code
    end

    def new_headteacher?
      aso_new_headteacher == "yes"
    end

    def options_array
      [
        {
          text: "Yes",
          value: "yes",
        },
        {
          text: "No",
          value: "no",
        },
      ]
    end
  end
end
