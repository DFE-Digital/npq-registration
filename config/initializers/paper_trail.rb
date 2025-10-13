require "./lib/paper_trail_extensions/version"

PaperTrail::Version.include PaperTrailExtensions::Version

PaperTrail.serializer = PaperTrail::Serializers::JSON

Rails.application.configure do
  console do
    if Rails.env.local?
      change_author = "#{Rails.env} user"
    else
      printf "Who are you?\n> "
      change_author = gets&.strip

      raise "Your name is required for the audit trail" if change_author.blank?
    end

    puts "Welcome #{change_author}!" # rubocop:disable Rails/Output

    PaperTrail.request.whodunnit = "Rails console: #{change_author}"
  end
end
