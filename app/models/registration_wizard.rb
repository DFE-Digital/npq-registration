class RegistrationWizard
  include ActiveModel::Model

  class InvalidStep < StandardError; end

  attr_reader :current_step, :params, :store

  def initialize(current_step:, store:, params: {})
    set_current_step(current_step)
    @params = params
    @store = store
  end

  def self.permitted_params_for_step(step)
    "Forms::#{step.to_s.camelcase}".constantize.permitted_params
  end

  def form
    @form ||= "Forms::#{current_step.to_s.camelcase}".constantize.new(params)
  end

  def save!
    params.to_h.each do |k, v|
      store[k] = v
    end

    if submission_step?
      User.create!(submission_params)
    end
  end

  def next_step_path
    form.next_step.to_s.dasherize
  end

  def previous_step_path
    form.previous_step.to_s.dasherize
  end

private

  def set_current_step(step)
    @current_step = steps.find { |s| s == step.to_sym }

    raise InvalidStep if @current_step.nil?
  end

  def steps
    %i[
      start
      share_provider
      teacher_reference_number
      name_changes
      updated_name
      not_sure_updated_name
      not_updated_name
      change_dqt
      dont_know_teacher_reference_number
      dont_have_teacher_reference_number
      contact_details
      complete
    ]
  end

  def submission_step?
    current_step == :contact_details
  end

  def submission_params
    params.slice(:email)
  end
end
