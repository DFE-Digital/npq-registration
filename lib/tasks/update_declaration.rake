namespace :update_declaration do
  desc "Void a declaration"
  task :void, %i[declaration_ecf_id] => :environment do |_t, args|
    logger = Logger.new($stdout)
    declaration = Declaration.find_by(ecf_id: args.declaration_ecf_id)
    raise "Declaration not found: #{args.declaration_ecf_id}" unless declaration

    service = Declarations::Void.new(declaration:)

    result = service.void

    if result
      logger.info("Declaration #{args.declaration_ecf_id} set to state #{service.declaration.state}")
    else
      logger.error(service.errors.full_messages.to_sentence)
    end
  end
end
