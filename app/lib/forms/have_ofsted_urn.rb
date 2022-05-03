module Forms
  class HaveOfstedUrn < Base
    attr_accessor :has_ofsted_urn

    validates :has_ofsted_urn, presence: true, inclusion: { in: %w[yes no] }

    def self.permitted_params
      %i[
        has_ofsted_urn
      ]
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
      :qualified_teacher_check
    end

    def options
      [
        OpenStruct.new(value: "yes",
                       text: "Yes",
                       link_errors: true),
        OpenStruct.new(value: "no",
                       text: "No",
                       link_errors: false),
      ]
    end
  end
end
