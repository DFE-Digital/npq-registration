class ExternalLink
  class VerificationError < StandardError; end

  class << self
    attr_writer :logger

    def config_path = Rails.root.join("config/external_links.yml")

    def all = mapping.values.map { new(it) }

    def fetch(key) = new(mapping.fetch(key.to_s))

    def verify_all = all.each(&:verify)

    def reset_cache = @mapping = nil

    def logger
      @logger ||= Logger.new($stdout)
    end

  private

    def mapping
      @mapping ||= YAML.load_file(config_path)
    end
  end

  attr_reader :url

  delegate :logger, to: :class

  def initialize(url)
    @url = url
  end

  def verify
    response = request(url)

    unless response.is_a? Net::HTTPSuccess
      fail "URL returned status #{response.code}"
    end

    logger.info("External link #{url} verified successfully")
    true
  end

private

  def request(url, limit = 5, headers: {})
    fail "Too many redirects" if limit.zero?

    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri, headers)

    if response.is_a? Net::HTTPRedirection
      # authorise-access-to-a-teaching-record redirects forever without cookies
      headers.merge!(cookie: response["set-cookie"]) if response.key?("set-cookie")
      location = URI.join(uri, response["location"])
      request(location, limit - 1, headers:)
    else
      response
    end
  end

  def fail(message)
    logger.fatal("External link #{url} failed verification: #{message}")
    raise VerificationError, message
  end
end
