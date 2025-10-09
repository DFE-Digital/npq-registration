class TimelineComponent < BaseComponent
  attr_reader :items

  def initialize(items:)
    @items = items
  end
end
