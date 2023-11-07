desc "Feature Flags"
namespace :feature_flags do
  desc "Initialize feature flags, ensure all available flags are in the interface (new flags will be initially disabled)"
  task initialize: :environment do
    Feature.initialize_feature_flags
  end
end
