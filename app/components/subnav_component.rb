# frozen_string_literal: true

class SubnavComponent < BaseComponent
  include ViewComponent::Slotable

  renders_many :nav_items, 'NavItemComponent'

  class NavItemComponent < BaseComponent
    attr_reader :path

    def initialize(path:)
      @path = path
    end

    def subnav_list_item_classes
      class_names(
        "app-subnav__list-item",
        "app-subnav__list-item--selected" => current_page?(path),
      )
    end
  end
end
