module Forms
  class KindOfNursery < Base
    attr_accessor :kind_of_nursery

    KIND_OF_NURSERY_PUBLIC_OPTIONS = %w[
      local_authority_maintained_nursery
      preschool_class_as_part_of_school
    ].freeze
    KIND_OF_NURSERY_PRIVATE_OPTIONS = %w[private_nursery].freeze
    KIND_OF_NURSERY_OPTIONS = KIND_OF_NURSERY_PUBLIC_OPTIONS + KIND_OF_NURSERY_PRIVATE_OPTIONS

    validates :kind_of_nursery, presence: true, inclusion: { in: KIND_OF_NURSERY_OPTIONS }

    def self.permitted_params
      %i[
        kind_of_nursery
      ]
    end

    def next_step
      if private_nursery?
        :have_ofsted_urn
      else
        :find_childcare_provider
      end
    end

    def previous_step
      :work_in_nursery
    end

    def private_nursery?
      KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(kind_of_nursery)
    end
  end
end
