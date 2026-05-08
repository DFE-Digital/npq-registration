# frozen_string_literal: true

namespace :yarn do
  desc "overrides the default install task to allow installing with --ignore-scripts"
  # rake task this is overriding can be found here: https://github.com/rails/rails/blob/v8.0.4.1/railties/lib/rails/tasks/yarn.rake
  task :install do # rubocop:disable Rails/RakeEnvironment
    system("yarn install --no-progress --frozen-lockfile --ignore-scripts")
  end
end

namespace :javascript do
  desc "overrides the default install task to allow installing with --ignore-scripts"
  # rake task this is overriding can be found here: https://github.com/rails/jsbundling-rails/blob/v1.3.1/lib/tasks/jsbundling/build.rake#L28
  task :install do # rubocop:disable Rails/RakeEnvironment
    system("yarn install --ignore-scripts")
  end
end

namespace :css do
  desc "overrides the default install task to allow installing with --ignore-scripts"
  # rake task this is overriding can be found here: https://github.com/rails/cssbundling-rails/blob/v1.4.3/lib/tasks/cssbundling/build.rake#L3
  task :install do # rubocop:disable Rails/RakeEnvironment
    system("yarn install --ignore-scripts")
  end
end
