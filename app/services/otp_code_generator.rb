class OtpCodeGenerator
  # Crockford's Base32 alphabet: digits and uppercase letters, with the ambiguous I, L, O and U removed.
  # See https://www.crockford.com/base32.html
  CROCKFORD_BASE32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ".chars.freeze
  CODE_LENGTH = 8
  VALIDITY_PERIOD = 5.minutes

  def call
    Array.new(CODE_LENGTH) { CROCKFORD_BASE32[SecureRandom.random_number(CROCKFORD_BASE32.size)] }.join
  end

  def self.expired?(expires_at)
    expires_at.nil? || expires_at < Time.zone.now
  end

  def self.matches?(entered_code:, stored_code:)
    normalize(entered_code) == stored_code
  end

  # Crockford decoding is case-insensitive and treats ambiguous letters as the digit it looks like (O->0, I/L->1).
  # The stored code only uses the characters in the alphabet, so we have to normalise the code entered by the user.
  def self.normalize(code)
    code.to_s.upcase.tr("OIL", "011")
  end
end
