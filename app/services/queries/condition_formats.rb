module Queries
  module ConditionFormats
    def extract_conditions(list, allowlist: nil)
      conditions = case list
                   when String
                     list.split(",")
                   when Array
                     list.compact
                   else
                     list
                   end

      return conditions if allowlist.blank?

      case conditions
      when Array
        conditions.intersection(allowlist)
      else
        conditions.in?(allowlist) ? conditions : nil
      end
    end
  end
end
