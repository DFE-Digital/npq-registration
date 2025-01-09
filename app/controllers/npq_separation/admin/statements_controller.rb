class NpqSeparation::Admin::StatementsController < NpqSeparation::AdminController
  before_action :ensure_super_admin
  before_action :set_cohort
  before_action :store_uploads, only: :create

  def new; end

  def create
    @service = Statements::BulkCreator.new(
      cohort: @cohort,
      statements_csv_id: bulk_creator_params[:statements_csv_id],
      contracts_csv_id: bulk_creator_params[:contracts_csv_id],
    )

    @statements = @service.call(dry_run:)

    if @service.errors.any?
      render :new
    elsif dry_run
      set_preview
      render
    else
      flash[:success] = "#{@statements.count} statements created successfully"
      redirect_to npq_separation_admin_cohort_path(@cohort)
    end
  end

private

  def set_cohort
    @cohort = Cohort.find(params[:cohort_id])
  end

  def set_preview
    @preview = {
      statements: @statements.uniq { [_1.year, _1.month] },
      contracts: @statements.group_by { _1.lead_provider.name }.transform_values { _1.first.contracts },
      lead_providers_count: @statements.uniq(&:lead_provider).count,
    }
  end

  def dry_run
    bulk_creator_params[:confirm] != "1"
  end

  def bulk_creator_params
    return {} if params[:statements_bulk_creator].blank?

    params.require(:statements_bulk_creator).permit(:statements_csv_id, :contracts_csv_id, :confirm)
  end

  def store_uploads
    return unless (p = params[:statements_bulk_creator])

    {
      statements_csv_file: :statements_csv_id,
      contracts_csv_file: :contracts_csv_id,
    }.each do |file_key, id_key|
      next unless (file = p.delete(file_key))

      p[id_key] = store_file(file)
    end
  end

  def store_file(file)
    ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename).signed_id
  end

  def ensure_super_admin
    unless current_admin.super_admin?
      flash[:error] = "You must be a super admin to create statements"
      redirect_to npq_separation_admin_cohort_path(params[:cohort_id])
    end
  end
end
