module NpqSeparation
  module Admin
    class HistoryComponent < ViewComponent::Base
      attr_reader :record, :changes

      def initialize(record:, &)
        @record = record
        @changes = build_changes(&)
      end

    private

      def build_changes(&block)
        record.versions.where(event: "update").where.not(object_changes: nil)
          .select { |version| (version.object_changes.keys - %w[updated_at]).any? }
          .pluck(:created_at, :whodunnit, :object_changes)
          .map do |created_at, whodunnit, object_changes|
            {
              title: object_changes
                .except("updated_at")
                .map { |key, value| show_object_changes(key, value) }.join(", "),
              by: show_whodunnit(whodunnit),
              at: created_at,
              description: block_given? ? block.call(record, created_at, object_changes) : nil,
            }
          end
      end

      def show_object_changes(key, change)
        if key =~ /_id$/
          label = key.sub(/_id$/, "")
          change_from = format_change(label, change[0])
          change_to = format_change(label, change[1])
        else
          label = key
          change_from = change[0]
          change_to = change[1]
        end

        record.class.human_attribute_name(label).tap do |output_string|
          output_string << " changed"
          output_string << " from #{change_from}" if change_from
          output_string << " to #{change_to}" if change_to
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
