module Users
  class FindOrCreateFromTeacherAuth
    def initialize(email:, full_name:, previous_names:, trn:)
      @email = email
      @full_name = full_name
      @previous_names = previous_names
      @trn = trn
    end

    attr_reader :email, :full_name, :previous_names, :trn

    def call
      user = User.find_or_initialize_by(email: email.downcase)
      user.assign_attributes(
        full_name: full_name,
        previous_names: previous_names,
        trn: trn,
      )
      user.ecf_id ||= SecureRandom.uuid
      user.save!

      user
    end
  end
end
