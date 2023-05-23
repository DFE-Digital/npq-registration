module Forms
  class KindOfNursery < Base
    KIND_OF_NURSERY_PUBLIC_OPTIONS = %w[
      local_authority_maintained_nursery
      preschool_class_as_part_of_school
    ].freeze

    KIND_OF_NURSERY_PRIVATE_OPTIONS = %w[
      private_nursery
      another_early_years_setting
    ].freeze
    KIND_OF_NURSERY_OPTIONS = KIND_OF_NURSERY_PUBLIC_OPTIONS + KIND_OF_NURSERY_PRIVATE_OPTIONS

    attr_accessor :kind_of_nursery

    validates :kind_of_nursery, presence: true, inclusion: { in: KIND_OF_NURSERY_OPTIONS }

    def self.permitted_params
      %i[kind_of_nursery]
    end

    def next_step
      if ofsted_route?
        :have_ofsted_urn
      else
        :find_childcare_provider
      end
    end

    def previous_step
      :work_setting
    end

    def question
      Forms::QuestionTypes::RadioButtonGroup.new(
        name: :kind_of_nursery,
        options:,
      )
    end

    def options
      [
        build_option_struct(value: "local_authority_maintained_nursery", link_errors: true),
        build_option_struct(value: "preschool_class_as_part_of_school"),
        build_option_struct(value: "private_nursery"),
        build_option_struct(value: "another_early_years_setting", divider: true),
      ]
    end

    def ofsted_route?
      KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(kind_of_nursery)
    end
  end
end
