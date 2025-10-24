module NpqSeparation
  module Admin
    class ApplicationHistoryComponent < BaseComponent
      attr_reader :record, :changes

      def initialize(record:, &)
        @record = record
        @changes = build_changes(&)
      end

    private

      def build_changes
        record.versions.where(event: "update").where.not(object_changes: nil)
          .select { |version| (version.object_changes.keys - %w[updated_at]).any? }
          .pluck(:created_at, :whodunnit, :object_changes)
          .map { |created_at, whodunnit, object_changes|
            object_changes.except("updated_at", "funding_eligiblity_status_code").map do |key, value|
              {
                title: show_object_changes(key, value),
                by: show_whodunnit(whodunnit),
                at: created_at,
                description: description(record, object_changes, created_at, key, value),
              }
            end
          }.flatten
      end

      def show_object_changes(key, change)
        if key =~ /_id$/
          label = key.sub(/_id$/, "")
          change_to = "[#{format_change(label, change[1])}]"
        else
          label = key
          change_to = "[#{format_boolean(change[1])}]"
        end

        record.class.human_attribute_name(label).tap do |output_string|
          if key == "notes"
            output_string << " updated"
          else
            output_string << " changed"
            output_string << " to #{change_to}" if change_to
          end
        end
      end

      def description(record, object_changes, created_at, key, value)
        case key
        when "training_status"
          reason = record.lookup_state_change_reason(changed_at: created_at, changed_status: value[1])
          { inset: "Reason for training status change: #{reason}" } if reason
        when "notes"
          { details_summary: "Review notes", details: simple_format(value[1]) }
        when "eligible_for_funding"
          { bullet: "Status code changed to [#{object_changes['funding_eligiblity_status_code'][1]}]" }
        end
      end

      def format_change(label, change)
        return unless change

        fallback = "ID: #{change}"
        reflection = record.class.reflections[label]
        if reflection
          object = reflection.klass.find(change)
          object.respond_to?(:name) ? object.name : fallback
        else
          fallback
        end
      end

      def format_boolean(value)
        if [TrueClass, FalseClass].include?(value.class)
          value ? "Yes" : "No"
        else
          value
        end
      end

      def show_whodunnit(whodunnit)
        if whodunnit.nil?
          "unknown"
        elsif whodunnit.match(/Admin\ (\d+)/)
          ::Admin.find(whodunnit.match(/Admin\ (\d+)/)[1]).full_name
        elsif whodunnit.match(/Public User\ (\d+)/)
          User.find(whodunnit.match(/Public User\ (\d+)/)[1]).full_name
        elsif whodunnit.match(/Lead provider\ (\d+)/)
          LeadProvider.find(whodunnit.match(/Lead provider\ (\d+)/)[1]).name
        else
          whodunnit
        end
      rescue ActiveRecord::RecordNotFound
        whodunnit
      end
    end
  end
end
