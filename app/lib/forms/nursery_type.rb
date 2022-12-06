module Forms
  class NurseryType < Base
    KIND_OF_NURSERY_PUBLIC_OPTIONS = %w[
      local_authority_maintained_nursery
      preschool_class_as_part_of_school
    ].freeze

    KIND_OF_NURSERY_PRIVATE_OPTIONS = %w[
      early_years_or_childcare
      another_early_years_setting
    ].freeze

    ALL_OPTIONS = [KIND_OF_NURSERY_PUBLIC_OPTIONS, KIND_OF_NURSERY_PRIVATE_OPTIONS].flatten

    attr_accessor :nursery_type

    validates :nursery_type, presence: true, inclusion: { in: ALL_OPTIONS }

    def self.permitted_params
      %i[nursery_type]
    end

    def next_step
      if non_ofsted_route?
        :find_childcare_provider
      else
        :have_ofsted_urn
      end
    end

    def previous_step
      if wizard.tra_get_an_identity_omniauth_integration_active?
        :work_setting
      else
        :qualified_teacher_check
      end
    end

    def non_ofsted_route?
      KIND_OF_NURSERY_PUBLIC_OPTIONS.include?(nursery_type)
    end
  end
end
