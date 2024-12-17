module Helpers
  module BulkOperations
    def applications_file
      return @applications_file if @applications_file

      @applications_file = Tempfile.new.tap do |file|
        Application.find_each do |application|
          file.write "#{application.ecf_id}\n"
        end
        file.rewind
      end
    end

    def empty_applications_file
      return @empty_applications_file if @empty_applications_file

      @empty_applications_file = Tempfile.new
    end

    def wrong_format_file
      return @wrong_format_file if @wrong_format_file

      @wrong_format_file = Tempfile.new.tap do |file|
        file.write "one,two\nthree,four\n"
        file.rewind
      end
    end
  end
end
