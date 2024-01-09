module Migration
  class Reconciler
    def orphaned
      @orphaned ||= matches.select(&:orphaned?)
    end

    def orphaned_ecf
      @orphaned_ecf ||= orphaned.select { |m| NamespaceCheck.ecf?(m.orphan) }
    end

    def orphaned_npq
      @orphaned_npq ||= orphaned.select { |m| NamespaceCheck.npq?(m.orphan) }
    end

    def duplicated
      @duplicated ||= matches.select(&:duplicated?)
    end

    def matched
      @matched ||= matches - (orphaned + duplicated)
    end

    def matches
      @matches ||= begin
        matched_objects = Set.new
        matches = []

        all_objects.each do |obj|
          next if matched_objects.include?(obj)

          matching_objects = indexer.lookup(obj)
          matched_objects.merge(matching_objects)
          matches << Match.new(matching_objects)
        end

        matches
      end
    end

    def indexes
      raise NoMethodError, "subclass must implement #indexes"
    end

    def orphaned_matches
      raise NoMethodError, "subclass must implement #orphaned_matches"
    end

  protected

    def all_objects
      raise NoMethodError, "subclass must implement #all_objects"
    end

  private

    def indexer
      @indexer ||= Indexer.new(indexes, all_objects)
    end
  end
end
