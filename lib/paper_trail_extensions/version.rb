module PaperTrailExtensions
  module Version
    def self.included(base)
      base.after_commit :send_to_dfe_analytics, on: :create
    end

  private

    def send_to_dfe_analytics
      StreamVersionsToBigQueryJob.perform_later(attributes["whodunnit"], analytics_data)
    end

    def analytics_data
      table_name = attributes["item_type"].constantize.table_name

      { "item_table_name" => table_name }.tap do |data|
        data.merge!(attributes.except("id", "item_type", "object", "object_changes"))
        data["object_changes"] = attributes["object_changes"]&.keys
      end
    end
  end
end
