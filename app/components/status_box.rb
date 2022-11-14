class StatusBox < ViewComponent::Base
  attr_reader :url, :number, :label, :percentage, :small

  def initialize(number:, label:, percentage: nil, url: nil, small: false)
    @url = url
    @number = number
    @label = label
    @percentage = percentage
    @small = small
  end
end
