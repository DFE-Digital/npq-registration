class ExternalLink
  class VerificationError < StandardError; end

  CONFIG_PATH = Rails.root.join("config/external_links.yml").freeze

  class << self
    def all = mapping.values.map { new(url: it["url"], skip_check: it["skip_check"]) }

    def fetch(key) = new(url: mapping.fetch(key.to_s)["url"])

    def verify_all = all.each(&:verify)

    def reset_cache = @mapping = nil

  private

    def mapping
      @mapping ||= YAML.load_file(CONFIG_PATH)
    end
  end

  attr_reader :url, :skip_check

  def initialize(url:, skip_check: false)
    @url = url
    @skip_check = skip_check
  end

  def verify
    return false if skip_check

    response = request(url)

    unless response.is_a? Net::HTTPSuccess
      fail "URL returned status #{response.code}"
    end

    logger.info("External link #{url} verified successfully")
    true
  end

private

  def request(url, limit = 5, headers: default_headers)
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

  def default_headers
    {
      "user-agent" => "Mozilla/5.0 Chrome/139.0.0.0", # wrong/bad but GIAS 403s without spoofing user agent
    }
  end

  def fail(message)
    logger.fatal("External link #{url} failed verification: #{message}")
    raise VerificationError, message
  end

  def logger
    @logger ||= Logger.new($stdout) # TODO: does this need to be a class method?
  end
end
