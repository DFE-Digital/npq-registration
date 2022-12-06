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
      :nursery_type
    end

    def options
      [
        build_option_struct(value: "yes", link_errors: true),
        build_option_struct(value: "no"),
      ]
    end
  end
end
