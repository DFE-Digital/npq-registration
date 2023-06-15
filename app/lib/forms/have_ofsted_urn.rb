module Forms
  class HaveOfstedUrn < Base
    QUESTION_NAME = :has_ofsted_urn

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true, inclusion: { in: %w[yes no] }

    def self.permitted_params
      [QUESTION_NAME]
    end

    # If you say you have no ofsted URN, then we should
    # make sure you do not have an institution saved.
    # This is to ensure people do not end up saying
    # no but having invalid data where they entered
    # one present.
    def after_save
      return if wizard.query_store.has_ofsted_urn?

      wizard.store["institution_identifier"] = nil
      wizard.store["institution_name"] = nil
    end

    def next_step
      case has_ofsted_urn
      when "yes"
        :choose_private_childcare_provider
      when "no"
        :choose_your_npq
      end
    end

    def previous_step
      :kind_of_nursery
    end

    def questions
      [
        Forms::QuestionTypes::RadioButtonGroup.new(
          name: QUESTION_NAME,
          locale_name: QUESTION_NAME,
          options:,
          style_options: { legend: { size: "xl", tag: "h1" } },
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "yes", link_errors: true),
        build_option_struct(value: "no"),
      ]
    end
  end
end
