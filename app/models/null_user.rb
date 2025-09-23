class NullUser < User
  def null_user?
    true
  end

  def actual_user?
    false
  end

  def flipper_id
    "User;#{feature_flag_id}"
  end

  attr_accessor :feature_flag_id
end
