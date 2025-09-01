module NpqSeparation
  class ServiceNavigationComponent < ViewComponent::Base
    FULL_SERVICE_NAME = "Register for a national professional qualification".freeze
    ADMIN_SERVICE_NAME = "Manage NPQs".freeze

    attr_reader :actor, :request

    def initialize(actor:, request:)
      @actor = actor
      @request = request
    end

    def call
      render GovukComponent::ServiceNavigationComponent.new(
        current_path: request.path,
        navigation_items:,
        service_name: admin? ? ADMIN_SERVICE_NAME : FULL_SERVICE_NAME,
        service_url: root_path,
      )
    end

  private

    def navigation_items
      if admin?
        admin_navigation_items
      elsif actor.present?
        user_navigation_items
      else
        []
      end
    end

    def admin?
      actor.is_a?(::Admin)
    end

    def admin_navigation_items
      [
        *NavigationStructures::AdminNavigationStructure.new(actor).service_navigation_items,
        sign_out_item,
      ]
    end

    def user_navigation_items
      [
        dfe_identity_account_item,
        npq_account_item,
        sign_out_item,
      ].compact
    end

    def dfe_identity_account_item
      {
        href: helpers.identity_link_uri(request.original_url),
        text: "DfE Identity account",
      }
    end

    def npq_account_item
      return unless actor.applications.any?

      {
        href: helpers.application_count_based_account_url,
        text: "NPQ account",
      }
    end

    def sign_out_item
      html_attributes = admin? ? { style: "margin-left: auto;" } : {}

      {
        href: helpers.sign_out_user_path,
        text: "Sign out",
        html_attributes:,
      }
    end
  end
end
