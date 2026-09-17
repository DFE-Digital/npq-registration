# frozen_string_literal: true

module Admin::Cohorts
  class ExtendStatementsController < AdminController
    before_action :require_super_admin, :set_cohort, :set_service

    def show; end

    def create
      if @service.invalid?
        render :show, status: :unprocessable_content
      elsif @service.schedule_change
        flash[:success] =
          "Cohort is being extended with additional statements, this may take a few minutes"
        redirect_to admin_cohort_path(@cohort)
      else
        redirect_to admin_cohort_path(@cohort)
      end
    end

  private

    def set_cohort
      @cohort = Cohort.find(params[:cohort_id])
    end

    def set_service
      @service = ::Cohorts::ExtendStatements.new(cohort: @cohort, extension_date:)
    end

    def extension_date
      eparams = params
        .fetch(:cohorts_extend_statements, {})
        .permit(:extension_date)

      date_args = [
        eparams["extension_date(1i)"]&.to_i,
        eparams["extension_date(2i)"]&.to_i,
      ]

      return if date_args.any?(&:blank?) || date_args.any?(&:zero?)

      Date.new(*date_args)
    rescue Date::Error
      nil
    end
  end
end
