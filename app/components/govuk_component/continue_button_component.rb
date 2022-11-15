class GovukComponent::ContinueButtonComponent < GovukComponent::Base
  BUTTON_ATTRIBUTES = {
    draggable: "false",
    data: { module: "govuk-button" },
  }.freeze

  LINK_ATTRIBUTES = BUTTON_ATTRIBUTES.merge({ role: "button" }).freeze

  attr_reader :text, :href, :as_button

  def initialize(text:, href:, as_button: false, classes: [], html_attributes: {})
    @text = text
    @href = href
    @as_button = as_button

    super(classes:, html_attributes:)
  end

  def call
    if as_button
      button_to(href, **html_attributes) { text }
    else
      link_to(href, **html_attributes) { text }
    end
  end

private

  def default_attributes
    (as_button ? BUTTON_ATTRIBUTES : LINK_ATTRIBUTES)
      .merge({ class: %w[govuk-button] })
  end
end
