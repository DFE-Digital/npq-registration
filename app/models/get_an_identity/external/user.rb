module GetAnIdentity
  module External
    class User
      class InvalidTokenError < StandardError; end
      class NotFoundError < StandardError; end

      def self.find(id)
        new(id:)
      end

      attr_reader :id,
                  :uid,
                  :email,
                  :full_name,
                  :date_of_birth,
                  :trn,
                  :mobile_number,
                  :merged_user_ids,
                  :trn_lookup_status,
                  :raw

      def initialize(id:)
        @id = id
        self.load
      end

    private

      def request_user
        url = "#{ENV.fetch('TRA_OIDC_DOMAIN')}/api/v1/users/#{id}"
        headers = { "Authorization" => "Bearer #{GetAnIdentity::External::AccessToken.new}" }

        HTTParty.get(url, headers:).tap do |response|
          case response.code
          when 400
            raise NotFoundError, "User with id #{id} not found"
          when 401
            raise InvalidTokenError, "Invalid access token"
          end
        end
      end

      def load
        response = request_user

        @uid = response["userId"]
        @email = response["email"]
        @full_name = [response["firstName"], response["lastName"]].join(" ")
        @date_of_birth = Date.parse(response["dateOfBirth"], "%Y-%m-%d")
        @trn = response["trn"]
        @mobile_number = response["mobileNumber"]
        @merged_user_ids = response["mergedUserIds"]
        @trn_lookup_status = response["trnLookupStatus"]
        @raw = response.parsed_response
      end
    end
  end
end
