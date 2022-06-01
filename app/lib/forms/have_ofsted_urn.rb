module Forms
  class HaveOfstedUrn < Base
    attr_accessor :has_ofsted_urn

    validates :has_ofsted_urn, presence: true, inclusion: { in: %w[yes no] }

    def self.permitted_params
      %i[
        has_ofsted_urn
      ]
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
      if wizard.query_store.works_in_nursery?
        :kind_of_nursery
      else
        :work_in_nursery
      end
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
