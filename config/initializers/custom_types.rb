class StrictDecimal < ActiveModel::Type::Integer
  def cast(value)
    if value.is_a?(String) && value !~ /\A-?\d+(|\.\d+)\z/
      nil
    else
      super
    end
  end
end

class StrictInteger < ActiveModel::Type::Integer
  def cast(value)
    if value.is_a?(String) && value !~ /\A-?\d+\z/
      nil
    else
      super
    end
  end
end

ActiveModel::Type.register(:strict_decimal, StrictDecimal)
ActiveModel::Type.register(:strict_integer, StrictInteger)
