module Helpers
  module TempfileHelper
    def tempfile(content)
      Tempfile.new.tap do |file|
        file.write(content)
        file.rewind
      end
    end
  end
end
