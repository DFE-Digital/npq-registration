namespace :one_off do
  desc "One off task to create a user"
  task :create_user, %i[ecf_id email full_name] => :versioned_environment do |_t, args|
    ecf_id = args[:ecf_id]
    email = args[:email]
    full_name = args[:full_name]

    User.create!(ecf_id:, email:, full_name:)
  end
end
