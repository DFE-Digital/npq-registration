module Services
  module GetAnIdentity
    class UserUpdater
      def self.call(user:)
        new(user: user).call
      end

      attr_reader :user

      def initialize(user:)
        @user = user
      end

      def call
        user = User.first
        get_an_identity_user = ::GetAnIdentity::User.find(user.get_an_identity_id)

        # GetAnIdentity::User#uid may not be the same as User#get_an_identity_id
        # This is because while those two values both refer to the same thing,
        # in cases of deduping we may get a new uid from GetAnIdentity when the user we
        # looked up has been merged into another.
        # By setting that new UID on the user, we can replicate that result within NPQ
        user.update!(
          full_name: get_an_identity_user.full_name,
          date_of_birth: get_an_identity_user.date_of_birth,
          trn: get_an_identity_user.trn,
          uid: get_an_identity_user.uid,
          email: get_an_identity_user.email,
          updated_from_tra_at: Time.zone.now,
        )
      end
    end
  end
end
