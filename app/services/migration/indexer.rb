module Migration
  class Indexer
    class UnindexableError < ArgumentError; end
    class NoIndexesError < ArgumentError; end

    attr_reader :indexes, :objects

    def initialize(indexes, objects)
      @indexes = indexes
      @objects = objects

      raise NoIndexesError, "you must specify indexes" if indexes.blank?
    end

    # Looks up objects in the index that match the passed in
    # object (based on the indexed attributes). It will recursively
    # perform a lookup on any matched objects in order to expand the
    # search as far as possible and infer matches.
    def lookup(obj, looked_up_objects = Set.new)
      # End condition for recursion; we've already looked up this object.
      return Set[obj] if looked_up_objects.include?(obj)

      # Add the object to the set of looked up objects.
      looked_up_objects.add(obj)

      # For each indexed attribute.
      indexes
        # Fetch the matching objects from the index.
        .map { |attr| fetch(obj, attr) }
        # Flatten the array of matching objects to a single array.
        .flatten
        # Convert to a set (removing duplicates).
        .reduce(Set.new, &:merge)
        # Recursively lookup each matching object to find further matches.
        .flat_map { |matching_obj| lookup(matching_obj, looked_up_objects) }
        # Convert to a set (removing duplicates).
        .reduce(Set.new, &:merge)
    end

  private

    # Fetches objects from the index for the given attribute.
    def fetch(obj, attr)
      # Get the keys from the value of the attribute on the object.
      keys = sanitize_keys(obj, attr)
      # Compact an array of objects from the index for each key.
      keys.map { |k| index.dig(attr, k) }.compact
    end

    # Construct the index by indexing each individual object.
    def index
      @index ||= indexes.index_with { {} }.tap do |index|
        objects.each { |obj| index_object(obj, index) }
      end
    end

    # Add an object to the index. An index might look like:
    #
    # {
    #   index1: {
    #     key1: Set[object1, object2],
    #   },
    #   index2: {
    #     key1: Set[object1, object3],
    #   }
    # }
    #
    # This means that object1 and object2 both share the value 'key1'
    # for the attribute 'index1'. Note that array values are indexed individually,
    # so if object1 has an array value of '[key1, key2]' for attribute 'index1' the
    # index will look like this:
    #
    # {
    #   index1: {
    #     key1: Set[object1],
    #     key2: Set[object1],
    #   }
    # }
    #
    # The purpose of this is to ensure we match objects that have a common array
    # value (for example if indexing users we can then infer user1 matches user2
    # if both share an application id on an indexed `application_ids` attribute).
    def index_object(obj, index)
      # Add the object to the index for each indexed attribute.
      results = indexes.map { |attr| index_object_attribute(obj, index, attr) }

      raise UnindexableError, "unable to index #{obj}" if results.all?(&:nil?)
    end

    # Add the object to the index for each indexed attribute.
    def index_object_attribute(obj, index, attr)
      # Get the keys from the value of the attribute on the object.
      keys = sanitize_keys(obj, attr)
      return if keys.blank?

      # Add the object to the index for each key.
      keys.each do |key|
        index[attr][key] ||= Set.new
        index[attr][key].add(obj)
      end
    end

    # Given an object and an attribute, returns a set of indexed keys.
    # Usually this will be a single key, but if the attribute
    # has an array value it will be multiple keys.
    def sanitize_keys(obj, attr)
      # If the object doesn't respond to the attribute, return an empty set.
      return Set.new unless obj.respond_to?(attr)

      # Return a set of keys, downcased and converted to strings for
      # case-insensitive comparisons.
      keys = Array.wrap(obj.send(attr))
      keys.map { |v| v.to_s.downcase }
    end
  end
end
