module Helpers
  module BulkOperations
    def applications_file
      @applications_file ||= tempfile_with_bom(Application.all.pluck(:ecf_id).join("\n"))
    end

    def empty_file
      @empty_file ||= Tempfile.new
    end

    def wrong_format_file
      @wrong_format_file ||= tempfile_with_bom("one,two\nthree,four\n")
    end
  end
end
