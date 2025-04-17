module NpqSeparation::Admin::BulkOperations
  class BaseController < NpqSeparation::AdminController
    before_action :find_bulk_operation, only: %i[run show]
    before_action :set_bulk_operations, :initialize_bulk_operation, only: %i[index create]

    def run
      @bulk_operation.update!(started_at: Time.zone.now, ran_by_admin_id: current_admin.id)
      bulk_operation_job_class.perform_later(bulk_operation_id: @bulk_operation.id)
      redirect_to bulk_operation_index
    end

    def show
      # empty method, because rubocop will complain in the before_action otherwise
    end

    def create
      if (file = params.dig(bulk_operation_param_key, :file))
        bulk_operation_class.not_started.destroy_all
        @bulk_operation.file.attach(file)
        if @bulk_operation.save
          flash[:success] = "File #{@bulk_operation.file.filename} uploaded successfully."
          return redirect_to bulk_operation_index
        end
      end

      render :index, status: :unprocessable_entity
    end

  private

    def bulk_operation_job_class
      "#{bulk_operation_class}Job".constantize
    end

    def bulk_operation_param_key
      bulk_operation_class.model_name.param_key
    end

    def find_bulk_operation
      @bulk_operation = bulk_operation_class.find(params[:id])
    end

    def sort_order
      %i[created_at id]
    end

    def set_bulk_operations
      @bulk_operations = bulk_operation_class.all.includes([file_attachment: :blob]).order(sort_order)
    end

    def initialize_bulk_operation
      @bulk_operation = bulk_operation_class.new(admin: current_admin)
    end
  end
end
