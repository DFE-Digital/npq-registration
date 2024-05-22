# frozen_string_literal: true

module ValidTestDataGenerators
  class StatementsPopulater
    class << self
      def populate(lead_provider:, cohort:)
        new(lead_provider:, cohort:).populate
      end
    end

    def populate
      return unless Rails.env.in?(%w[development separation])

      logger.info "StatementsPopulater: Started!"

      ActiveRecord::Base.transaction do
        create_statements!
      end

      logger.info "StatementsPopulater: Finished!"
    end

  private

    attr_reader :lead_provider, :cohort, :logger

    def initialize(lead_provider:, cohort:, logger: Rails.logger)
      @lead_provider = lead_provider
      @cohort = cohort
      @logger = logger
    end

    def create_statements!
      logger.info "StatementsPopulater: Creating #{cohort.start_year} cohort statements for #{lead_provider.name}"

      statements_names(cohort.start_year).each_with_index do |statements_name, index|
        month = statements_name[0]
        year = statements_name[1]

        logger.info "StatementsPopulater: Creating Statement #{month}/#{year}"

        statement = Statement.find_by(
          month:,
          year:,
          lead_provider:,
          cohort:,
        )

        next if statement

        deadline_date = Date.new(cohort.start_year, 12, 25) + index.months
        payment_date = Date.new(cohort.start_year.succ, 1, 25) + index.months

        state = state_for(payment_date, deadline_date)

        FactoryBot.create(:statement,
                          month:,
                          year:,
                          lead_provider:,
                          deadline_date:,
                          payment_date:,
                          cohort:,
                          output_fee: [true, false].sample,
                          state:,
                          marked_as_paid_at: state == :paid ? payment_date : nil,
                          ecf_id: SecureRandom.uuid)

        logger.info "StatementsPopulater: Statement #{month}/#{year} successfully created!"
      end

      logger.info "StatementsPopulater: #{cohort.start_year} cohort statements for #{lead_provider.name} successfully created!"
    end

    def state_for(payment_date, deadline_date)
      return :paid if payment_date < Date.current
      return :payable if Date.current.between?(deadline_date, payment_date)

      :open
    end

    def statements_names(cohort_start_year)
      1.upto(3).map { |i|
        month_names(cohort_start_year + i)
      }.flatten(1)
    end

    def month_names(year)
      1.upto(12).map do |month|
        Date.new(year, month).strftime("%-m %Y").split
      end
    end
  end
end
