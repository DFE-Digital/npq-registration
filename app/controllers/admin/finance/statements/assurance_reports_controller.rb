# frozen_string_literal: true

class Admin::Finance::Statements::AssuranceReportsController < AdminController
  def show
    @statement = Statement.find(params[:id])
    @declarations = AssuranceReports::Query.new(@statement).declarations
    @serializer = AssuranceReports::CsvSerializer.new(@declarations, @statement)

    respond_to do |format|
      format.csv do
        send_data @serializer.serialize, filename: @serializer.filename
      end
    end
  end
end
