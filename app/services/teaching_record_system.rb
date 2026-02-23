module TeachingRecordSystem
  class Error < StandardError; end
  class TimeoutError < Error; end
  class ApiError < Error; end
end
