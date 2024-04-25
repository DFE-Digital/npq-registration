class Query
  def extract_conditions(list)
    case list
    when String
      list.split(",")
    when Array
      list.compact
    else
      list
    end
  end
end
