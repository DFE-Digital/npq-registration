RSpec.configure do |config|
  config.before(:suite) do
    Services::Courses::DefinitionLoader.call(silent: true)
    Services::LeadProviders::Updater.call
  end
end
