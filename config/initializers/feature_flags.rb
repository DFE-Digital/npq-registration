Services::Feature::FEATURE_FLAG_KEYS.each do |feature_flag_key|
  Flipper.add(feature_flag_key)
end
