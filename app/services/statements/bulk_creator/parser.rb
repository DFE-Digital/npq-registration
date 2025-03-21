module Statements
  class BulkCreator
    class Parser < Array
      attr_accessor :error

      def self.read(csv_file, row_class)
        lines = CSV.read(csv_file, headers: true)

        if lines.none?
          new_with_error "No rows found"
        elsif (missing_headers = row_class.attribute_names - lines.first.headers).any?
          new_with_error "Missing headers: #{missing_headers.join(", ")}"
        else
          new(lines.map { row_class.new(_1.to_h.slice(*row_class.attribute_names)) })
        end
      rescue CSV::MalformedCSVError
        new_with_error "must be CSV format"
      end

      def self.new_with_error(error)
        new.tap { _1.error = error }
      end

      def valid?
        error.nil? && present? && valid_rows.count == count
      end

      def valid_rows
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
