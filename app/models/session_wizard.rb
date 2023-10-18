class SessionWizard
  include ActiveModel::Model

  class InvalidStep < StandardError; end

  attr_reader :current_step, :params, :store, :session

  def initialize(current_step:, store:, session:, params: {})
    set_current_step(current_step)
    @params = params
    @store = store
    @session = session
  end

  def self.permitted_params_for_step(step)
    "Questionnaires::#{step.to_s.camelcase}".constantize.permitted_params
  end

  def form
    return @form if @form

    hash = load_from_store
    hash.merge!(params)
    hash.merge!(wizard: self)

    @form ||= form_class.new(hash)
  end

  def save!
    form.attributes.each do |k, v|
      store[k.to_s] = v
    end

    form.after_save
  end

  def next_step_path
    form.next_step.to_s.dasherize
  end

  def previous_step_path
    form.previous_step.to_s.dasherize
  end

  def finished?
    form.next_step.nil?
  end

private

  def load_from_store
    {}
  end

  def form_class
    @form_class ||= "Questionnaires::#{current_step.to_s.camelcase}".constantize
  end

  def set_current_step(step)
    @current_step = steps.find { |s| s == step.to_sym }

    raise InvalidStep if @current_step.nil?
  end

  def steps
    %i[
      sign_in
      sign_in_code
    ]
  end
end
