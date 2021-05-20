module Services
  class OtpCodeGenerator
    def call
      rand(100_000..999_999).to_s
    end
  end
end
