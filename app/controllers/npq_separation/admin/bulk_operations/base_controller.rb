module NpqSeparation::Admin::BulkOperations
  class BaseController < NpqSeparation::AdminController
    before_action :find_bulk_operation, only: %i[run show]

    def run
      perform_bulk_action
    end

    def show
      # empty method, because rubocop will complain in the before_action otherwise
    end

    def create
      if (file = params.dig(bulk_operation_param_key, :file))
        bulk_operation_class.not_started.destroy_all
        @bulk_operation.file.attach(file)
        if @bulk_operation.valid?
          @bulk_operation.save!
          @bulk_operation.update!(row_count: @bulk_operation.file.download.lines.count)
          return redirect_to bulk_operation_index
        end
      end

      render :index, status: :unprocessable_entity
    end

  private

    def find_bulk_operation
      @bulk_operation = bulk_operation_class.find(params[:id])
    end

    def perform_bulk_action
      @bulk_operation.update!(started_at: Time.zone.now, ran_by_admin_id: current_admin.id)
      bulk_operation_job_class.perform_later(bulk_operation_id: @bulk_operation.id)
      redirect_to bulk_operation_index
    end
  end
end
