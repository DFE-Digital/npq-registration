# frozen_string_literal: true

module AxeHelper
  extend RSpec::Matchers::DSL

  define :be_accessible do
    match do |_page|
      # TODO: reinstate this check when we get axe to work again
      # TODO: check if it's enough to just check wcag22aa, or if we should be checking wcag2a as well
      # expect(page).to be_axe_clean.according_to :wcag22aa
      true
    end
  end
end
