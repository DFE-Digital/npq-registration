class OTP
  class Invalid < ArgumentError; end

  # Crockford's Base32 alphabet: digits and uppercase letters, with the ambiguous I, L, O and U removed.
  # Crockford decoding is case-insensitive and treats some letters as the digit they look like (O->0, I/L->1).
  # The stored code only uses the alphabet, so we normalise the code entered by the user before secure comparing.
  # See https://www.crockford.com/base32.html
  CROCKFORD_BASE32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ".chars.freeze
  CODE_LENGTH = 8
  CODE_PATTERN = /\A[#{CROCKFORD_BASE32.join}]{#{CODE_LENGTH}}\z/
  VALIDITY_PERIOD = 5.minutes

  attr_reader :code, :expires_at

  class << self
    def generate
      new(code: random_code, expires_at: VALIDITY_PERIOD.from_now)
    end

    def normalize(code)
      code.to_s.upcase.tr("OIL", "011")
    end

    def valid_code_format?(code)
      code.to_s.match?(CODE_PATTERN)
    end

  private

    def random_code
      Array.new(CODE_LENGTH) { CROCKFORD_BASE32[SecureRandom.random_number(CROCKFORD_BASE32.size)] }.join
    end
  end

  def initialize(code:, expires_at:)
    raise Invalid, "#{code.inspect} is not a valid OTP code" unless self.class.valid_code_format?(code)
    raise Invalid, "#{expires_at.inspect} is not a valid expiry time" unless expires_at.acts_like?(:time)

    @code = code
    @expires_at = expires_at
  end

  def expired?
    expires_at < Time.current
  end

  def matches?(entered_code)
    ActiveSupport::SecurityUtils.secure_compare(self.class.normalize(entered_code), code)
  end
end
