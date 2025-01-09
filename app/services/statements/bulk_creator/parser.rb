module Statements
  class BulkCreator
    class Parser < Array
      attr_accessor :error

      def self.read(csv_file, row_class)
        lines = CSV.read(csv_file, headers: true, encoding: "bom|utf-8") # encoding needed for some Excel CSVs

        if lines.none?
          new.tap { _1.error = "No rows found" }
        elsif (missing_headers = row_class.attribute_names - lines.first.headers).any?
          new.tap { _1.error = "Missing headers: #{missing_headers.join(", ")}" }
        else
          new lines.map { row_class.new(_1.to_h.slice(*row_class.attribute_names)) }
        end
      end

      def valid?
        error.nil? && present? && valid.count == count
      end

      def valid
        select(&:valid?)
      end

      def errors
        return [] if valid?

        [error].compact + flat_map.with_index(2) do |object, line_number|
          object.errors.map { _1.full_message + " on line #{line_number}" }
        end
      end
    end
  end
end
