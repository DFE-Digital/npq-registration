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
      store[k.to_sym] = v
    end
  end

  def next_step_path
    index = steps.find_index(current_step)
    steps[index + 1].to_s.dasherize
  end

private

  def set_current_step(step)
    @current_step = steps.find { |s| s == step.to_sym }

    raise InvalidStep if @current_step.nil?
  end

  def steps
    %i[
      share_provider
      contact_details
    ]
  end
end
