class TimelineComponent < BaseComponent
  class TimelineItemComponent < BaseComponent
    attr_reader :title, :date

    def initialize(title:, date:)
      @title = title
      @date = date
    end
  end

  renders_many :items, "TimelineItemComponent"
end
