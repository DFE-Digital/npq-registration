# frozen_string_literal: true

class NpqSeparation::Admin::Finance::Statements::AdjustmentsController < NpqSeparation::AdminController
  before_action :set_statement

  def new
    @adjustment = @statement.adjustments.new
  end

  def create
    @create_adjustment_form = Admin::Adjustments::CreateAdjustmentForm.new(
      adjustment_params.merge(created_adjustment_ids: session[:created_adjustment_ids], statement: @statement),
    )

    if @create_adjustment_form.save_form
      session[:created_adjustment_ids] = @create_adjustment_form.created_adjustment_ids
      redirect_to npq_separation_admin_finance_statement_adjustments_path(@statement)
    else
      @adjustment = @create_adjustment_form
      render :new
    end
  end

  def index
    @add_another_form = Admin::Adjustments::AddAnotherAdjustmentForm.new(add_another_params.merge(statement: @statement))
    @create_adjustment_form = Admin::Adjustments::CreateAdjustmentForm.new(created_adjustment_ids: session[:created_adjustment_ids], statement: @statement)
    @adjustments = @create_adjustment_form.adjustments
  end

  def add_another
    index
    if @add_another_form.valid?
      if @add_another_form.adding_another_adjustment?
        redirect_to new_npq_separation_admin_finance_statement_adjustment_path(@statement)
      else
        session[:created_adjustment_ids] = nil
        redirect_to npq_separation_admin_finance_statement_path(@statement)
      end
    else
      render :index, status: :unprocessable_entity
    end
  end

private

  def set_statement
    @statement = Statement.find(params[:statement_id])
  end

  def adjustment_params
    params.require(:adjustment).permit(
      :description,
      :amount,
    )
  end

  def add_another_params
    params.permit(
      add_another_form: [:add_another],
    )[:add_another_form] || {}
  end
end
