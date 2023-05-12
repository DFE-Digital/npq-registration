class NpqPanel < ViewComponent::Base
  attr_reader :title, :body

  def initialize(title:, body: nil)
    @title = title
    @body = body
  end

  def body_classes
    array = %w[govuk-panel__body]

    if body && body[:classes]
      array.concat(body[:classes])
    end

    array
  end
end
