# frozen_string_literal: true

class NpqSeparation::Admin::Finance::Statements::AdjustmentsController < NpqSeparation::AdminController
  before_action :set_statement
  before_action :find_adjustment, only: %i[edit update delete destroy]
  before_action :set_show_all_adjustments, except: %i[create add_another]

  def new
    @adjustment = @statement.adjustments.new
    @cancel_url = if @show_all_adjustments
                    npq_separation_admin_finance_statement_adjustments_path(@statement, show_all_adjustments: @show_all_adjustments)
                  else
                    npq_separation_admin_finance_statement_path(@statement)
                  end
  end

  def create
    @create_adjustment_form = Admin::Adjustments::CreateAdjustmentForm.new(
      adjustment_params.merge(created_adjustment_ids: session[:created_adjustment_ids], statement: @statement),
    )

    if @create_adjustment_form.save_adjustment
      session[:created_adjustment_ids] = @create_adjustment_form.created_adjustment_ids
      show_all_adjustments = params[:adjustment][:show_all_adjustments] == "true"
      redirect_to npq_separation_admin_finance_statement_adjustments_path(@statement, show_all_adjustments:)
    else
      @adjustment = @create_adjustment_form
      render :new
    end
  end

  def index
    @add_another_form = Admin::Adjustments::AddAnotherAdjustmentForm.new(add_another_params.merge(statement: @statement))
    @create_adjustment_form = Admin::Adjustments::CreateAdjustmentForm.new(created_adjustment_ids: session[:created_adjustment_ids], statement: @statement)
    @adjustments = if @show_all_adjustments
                     @statement.adjustments
                   else
                     @create_adjustment_form.adjustments
                   end
  end

  def edit
    @cancel_url = npq_separation_admin_finance_statement_adjustments_path(@statement, show_all_adjustments: @show_all_adjustments)
  end

  def update
    @update_adjustment_form = Admin::Adjustments::UpdateAdjustmentForm.new(
      adjustment_params.merge(statement: @statement, adjustment: @adjustment),
    )
    if @update_adjustment_form.save_adjustment
      redirect_to npq_separation_admin_finance_statement_adjustments_path(@statement, show_all_adjustments: @show_all_adjustments)
    else
      @adjustment = @update_adjustment_form
      render :edit
    end
  end

  def add_another
    index

    if @add_another_form.invalid?
      render :index, status: :unprocessable_entity
    elsif @add_another_form.adding_another_adjustment?
      show_all_adjustments = params[:add_another_form][:show_all_adjustments] == "true"
      redirect_to new_npq_separation_admin_finance_statement_adjustment_path(@statement, show_all_adjustments:)
    else
      session[:created_adjustment_ids] = nil
      redirect_to npq_separation_admin_finance_statement_path(@statement)
    end
  end

  def delete
    # empty method, otherwise rubocop complains the before_action refers to a method that is not explicitly defined on the class
  end

  def destroy
    @destroy_adjustment_form = Admin::Adjustments::DestroyAdjustmentForm.new(
      statement: @statement, adjustment: @adjustment,
    )
    if @destroy_adjustment_form.destroy_adjustment
      redirect_to npq_separation_admin_finance_statement_adjustments_path(@statement, show_all_adjustments: @show_all_adjustments)
    else
      @adjustment = @destroy_adjustment_form
      render :delete
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

  def find_adjustment
    @adjustment = @statement.adjustments.find(params[:id])
  end

  def set_show_all_adjustments
    @show_all_adjustments = params[:show_all_adjustments] == "true"
  end
end
