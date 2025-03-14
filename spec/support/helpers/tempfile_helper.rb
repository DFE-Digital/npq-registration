module Helpers
  module TempfileHelper
    def tempfile(content)
      Tempfile.new.tap do |file|
        file.write(content)
        file.rewind
      end
    end

    # use this to simulate UTF-8 CSV from Excel which has an unnecessary BOM
    # n.b. CSV class will handle BOM when reading files, but not strings
    # e.g. CSV.parse(File.read('x.csv'))[0][0][0] may be an invisible character
    def tempfile_with_bom(content)
      tempfile("\xEF\xBB\xBF#{content}")
    end
  end
end
