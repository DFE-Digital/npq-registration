module Forms
  class TeacherCatchment < Base
    attr_accessor :teacher_catchment, :teacher_catchment_country

    validates :teacher_catchment, presence: true, inclusion: { in: %w[england scotland wales northern_ireland jersey_guernsey_isle_of_man another] }
    validates :teacher_catchment_country, presence: true,
                                          inclusion: { in: Services::AutocompleteCountries.names },
                                          if: proc { |f| f.teacher_catchment == "another" }

    def self.permitted_params
      %i[
        teacher_catchment
        teacher_catchment_country
      ]
    end

    def after_save
      return if teacher_catchment == "another"

      wizard.store["teacher_catchment_country"] = nil
    end

    def return_to_regular_flow_on_change?
      true
    end

    def next_step
      if changing_answer?
        if answers_will_change?
          :work_setting
        else
          :check_answers
        end
      else
        :work_setting
      end
    end

    def previous_step
      :provider_check
    end

    def options
      [
        build_option_struct(value: "england", link_errors: true),
        build_option_struct(value: "scotland"),
        build_option_struct(value: "wales"),
        build_option_struct(value: "northern_ireland"),
        build_option_struct(value: "jersey_guernsey_isle_of_man"),
        build_option_struct(value: "another", divider: "or", opts: { country_autocomplete: true }),
      ]
    end
  end
end
