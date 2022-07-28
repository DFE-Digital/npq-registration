class Admin::ManualValidationsController < AdminController
  def show
    @manual_validation_upload = ManualValidationUpload.new
  end

  def download
    data = Services::Exporters::ManualValidation.new.csv

    send_data(data, filename: "manual-validation.csv")
  end

  def create
    @manual_validation_upload = ManualValidationUpload.new(manual_validation_upload_params)

    flash[:upload_info] = Services::Importers::ManualValidation.new(
      path_to_csv: @manual_validation_upload.csv.tempfile,
    ).call

    redirect_to admin_manual_validations_path
  rescue Services::Importers::ManualValidation::InvalidHeadersError
    @manual_validation_upload.errors.add(:csv, "Invalid columns, CSV must only contain application_ecf_id and validated_trn")

    render :show
  end

private

  def manual_validation_upload_params
    params.require(:manual_validation_upload).permit(:csv)
  end
end
