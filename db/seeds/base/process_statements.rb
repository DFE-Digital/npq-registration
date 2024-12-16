helpers = Class.new { include ActiveSupport::Testing::TimeHelpers }.new

Cohort.all.find_each do |cohort|
  LeadProvider.all.find_each do |lead_provider|
    statement_scope  = Statement.where(cohort:, lead_provider:).order(deadline_date: :desc)
    latest_statement = statement_scope.with_output_fee.where("deadline_date < ?", Time.zone.today).first

    next unless latest_statement

    # Mark past statements (up to latest output fee statement) as paid
    statement_scope.where("deadline_date < ?", latest_statement.deadline_date).find_each do |statement|
      Statements::MarkAsPayable.new(statement:).mark
      Statements::MarkAsPaid.new(statement).mark
    end

    # Void some declarations on the previous paid output fee statement to create clawbacks on the latest statement
    helpers.travel_to latest_statement.deadline_date - 1.day do
      claw_back_from_statement = statement_scope.with_output_fee.where("deadline_date < ?", latest_statement.deadline_date).first
      claw_back_from_statement.declarations.where.not(state: "voided").limit(2).each do |declaration|
        errors = Declarations::Void.new(declaration:).tap(&:void).errors
        fail(errors.full_messages.join(", ")) if errors.any?
      end
    end

    # Now that it has clawbacks, mark the latest output fee statement open -> payable
    errors = Statements::MarkAsPayable.new(statement: latest_statement).tap(&:mark).errors
    fail(errors.full_messages.join(", ")) if errors.any?
  end
end
