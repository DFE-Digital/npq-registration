module GetAnIdentity
  class User
    def self.find(id)
      new(id:).tap(&:load)
    end

    attr_reader :id,
                :uid,
                :email,
                :full_name,
                :date_of_birth,
                :trn,
                :mobile_number,
                :merged_user_ids,
                :raw

    def initialize(id:)
      @id = id
    end

    def load
      url = "#{ENV.fetch('TRA_OIDC_DOMAIN')}/api/v1/users/#{id}"

      response = HTTParty.get(url, headers: { "Authorization" => "Bearer #{GetAnIdentity::AccessToken.new}" })

      @uid = response["userId"]
      @email = response["email"]
      @full_name = [response["firstName"], response["lastName"]].join(" ")
      @date_of_birth = Date.parse(response["dateOfBirth"], "%Y-%m-%d")
      @trn = response["trn"]
      @mobile_number = response["mobileNumber"]
      @merged_user_ids = response["mergedUserIds"]
      @raw = response.parsed_response
    end
  end
end
