module Services
  module Admin
    class DashboardStats
      attr_reader :start_time

      def initialize(start_time: nil)
        @start_time = start_time
      end

      def applications_created
        @applications_created ||= applications_since_start_time.count
      end

      def get_an_identity_applications_created
        @get_an_identity_applications_created ||= applications_since_start_time.joins(:user)
                   .where(users: { provider: :tra_openid_connect })
                   .count
      end

      def non_get_an_identity_applications_created
        @non_get_an_identity_applications_created ||= applications_since_start_time.joins(:user)
                   .where(users: { provider: nil })
                   .count
      end

      def get_an_identity_applications_created_percentage
        (get_an_identity_applications_created / applications_created.to_f * 100).to_i
      end

      def non_get_an_identity_applications_created_percentage
        (non_get_an_identity_applications_created / applications_created.to_f * 100).to_i
      end

    private

      def applications_since_start_time
        @applications_since_start_time ||= if start_time.present?
                                             Application.where("applications.created_at >= ?", start_time)
                                           else
                                             Application.all
                                           end
      end
    end
  end
end
