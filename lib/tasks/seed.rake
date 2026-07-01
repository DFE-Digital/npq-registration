namespace :seed do
  desc "Large-scale DB seeding"
  task :large_background, %i[times] => :versioned_environment do |_t, args|
    times = args.times.to_i

    if times < 1
      puts "times is less than 1 - doing nothing."
      exit 1
    end

    times.times { SeedingJob.perform_later }
  end

  desc "Large-scale DB seeding"
  task :large, %i[multiplier] => :versioned_environment do |_t, args|
    return unless Rails.env.in?(%w[development review staging sandbox])

    include ActiveSupport::NumberHelper

    PaperTrail.enabled = false
    Faker::Config.locale = "en-GB"

    # default multiplier of 2 - anything greater causes the worker to run out of memory and crash
    multiplier = if args.multiplier.blank?
                   2
                 else
                   args.multiplier.to_i
                 end

    if multiplier < 1
      puts "multiplier is less than 1 - doing nothing."
      exit 1
    end

    application_count = Application.count
    declaration_count = Declaration.count
    user_count = User.count

    puts "Seeding applications and declarations using multiplier: #{multiplier}"

    load(Rails.root.join("db/seeds/base/add_applications.rb"))
    load(Rails.root.join("db/seeds/base/add_declarations.rb"))

    (multiplier - 1).times do
      SeedApplications.new.seed
      SeedDelcarations.new.seed
    end

    puts "Before:"
    puts "Application.count: #{number_to_delimited(application_count)}"
    puts "Declaration.count: #{number_to_delimited(declaration_count)}"
    puts "User.count: #{number_to_delimited(user_count)}"

    puts "After:"
    puts "Application.count: #{number_to_delimited(Application.count)}"
    puts "Declaration.count: #{number_to_delimited(Declaration.count)}"
    puts "User.count: #{number_to_delimited(User.count)}"
    puts "done."
  end
end
