require "oj"

Blueprinter.configure do |config|
  config.generator = Oj
  config.datetime_format = ->(datetime) { datetime.nil? ? datetime : datetime.rfc3339 }
end
