module Helpers
  module FileHelper
    def wait_for_file_to_be_created(filename)
      1.upto(50) do
        sleep 0.1
        break if File.exist?(filename)
      end
      fail "File #{filename} was not created" unless File.exist?(filename)
    end
  end
end
