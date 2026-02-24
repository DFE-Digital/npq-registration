helpers = Class.new { include ActiveSupport::Testing::TimeHelpers }.new

Cohort.all.find_each do |cohort|
  LeadProvider.all.find_each do |lead_provider|
    statement_scope  = Statement.where(cohort:, lead_provider:).order(deadline_date: :desc)
    latest_statement = statement_scope.with_output_fee.where("deadline_date < ?", Time.zone.today).first

    next unless latest_statement

    # Mark past statements (up to latest output fee statement) as payable
    statement_scope.where("deadline_date < ?", latest_statement.deadline_date).where(state: "open").find_each do |statement|
      Statements::MarkAsPayable.new(statement:).mark
    end
    # Set mark_as_paid_at for payable statements from 2023, and mark them as paid - to match production
    Statement.where(state: "payable", year: 2023..).find_each do |statement|
      helpers.travel_to statement.payment_date - 8.days do
        statement.mark_as_paid_at!
        Statements::MarkAsPaid.new(statement).mark
      end
    end

    # Void some declarations on the previous paid output fee statement to create clawbacks on the latest statement
    helpers.travel_to latest_statement.deadline_date - 1.day do
      claw_back_from_statement = statement_scope.with_output_fee.where("deadline_date < ?", latest_statement.deadline_date).first
      next unless claw_back_from_statement

      claw_back_from_statement.declarations.where.not(state: "voided").limit(2).each do |declaration|
        errors = Declarations::Void.new(declaration:).tap(&:void).errors
        fail(errors.full_messages.join(", ")) if errors.any?
      end
    end

    errors = Statements::MarkAsPayable.new(statement: latest_statement).tap(&:mark).errors
    fail(errors.full_messages.join(", ")) if errors.any?
  end
end
