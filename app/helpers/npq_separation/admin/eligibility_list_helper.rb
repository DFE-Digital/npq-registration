module NpqSeparation::Admin::EligibilityListHelper
  def last_bulk_operation_status(bulk_operation)
    if bulk_operation&.finished?
      "Completed processing at #{bulk_operation.finished_at.to_formatted_s(:govuk_short)}"
    elsif bulk_operation&.started?
      "Processing - started at #{bulk_operation.started_at.to_formatted_s(:govuk_short)}"
    else
      "-"
    end
  end
end
