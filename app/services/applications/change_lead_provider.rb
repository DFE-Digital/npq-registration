# frozen_string_literal: true

module Applications
  class ChangeLeadProvider
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :application
    attribute :lead_provider_id, :integer

    validates :application, presence: true
    validates :lead_provider_id, presence: { message: "Choose a course provider" }
    validate :different_lead_provider, if: :application

    def change_lead_provider
      return false if invalid?

      application.update!(lead_provider: lead_provider)
    end

    def lead_provider_options
      current_cohort_lead_providers_offering_the_same_course = LeadProvider.for(course: application.course).pluck(:id)
      LeadProvider.where.not(id: application.lead_provider.id).pluck(:id, :name).map do |id, name|
        unless current_cohort_lead_providers_offering_the_same_course.include?(id)
          description = "This lead provider is not offering #{application.course.identifier} for the latest cohort"
        end
        OpenStruct.new(id:, name:, description:)
      end
    end

  private

    def lead_provider
      @lead_provider ||= LeadProvider.find(lead_provider_id)
    end

    def different_lead_provider
      errors.add(:lead_provider_id, :inclusion) if lead_provider_id == application.lead_provider.id
    end
  end
end
