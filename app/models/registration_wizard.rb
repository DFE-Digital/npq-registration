class RegistrationWizard
  include ActiveModel::Model

  class InvalidStep < StandardError; end

  attr_reader :current_step

  def initialize(current_step:)
    set_current_step(current_step)
  end

  def form
    @form ||= "Forms::#{current_step.to_s.camelcase}".constantize
  end

private

  def set_current_step(step)
    @current_step = steps.find { |s| s == step.to_sym }

    raise InvalidStep if @current_step.nil?
  end

  def steps
    [
      :share_provider,
    ]
  end
end
