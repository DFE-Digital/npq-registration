class AdminService::WorkplaceSearch
  attr_reader :q

  def initialize(q:)
    @offset = 0
    @limit = 0
    @scope_counts = {}
    @q = q
  end

  def count(_)
    scopes.inject(0) { |sum, scope| sum + scope.count }
  end

  def offset(offset)
    @offset = offset
    self
  end

  def limit(limit)
    @limit = limit
    self
  end

  def each(&blk)
    find_scopes.each(&blk)
  end

private

  def schools_scope
    chain = School.order(name: :asc)
    if q.present?
      chain = chain.where(urn: q)
      chain = chain.or(School.where("name ILIKE ?", "%#{q}%"))
    end

    chain
  end

  def local_authority_scope
    chain = LocalAuthority.order(name: :asc)
    if q.present?
      chain = chain.where("name ILIKE ?", "%#{q}%")
    end

    chain
  end

  def private_childcare_provider_scope
    chain = PrivateChildcareProvider.order(provider_name: :asc)
    if q.present?
      chain = chain.where(provider_urn: q)
      chain = chain.or(PrivateChildcareProvider.where("provider_name ILIKE ?", "%#{q}%"))
    end

    chain
  end

  def scopes
    @scopes ||= [
      schools_scope,
      private_childcare_provider_scope,
      local_authority_scope,
    ]
  end

  def find_scopes
    calculate_scopes_indexes

    scopes.each_with_object([]) do |scope, records|
      next unless @scope_indexes[scope.class]

      # creating initial records array for the records on current page
      if (scope_range = @scope_indexes[scope.class]).include?(@offset)
        current_offset = @offset - scope_range.begin
        records.push(*scope.offset(current_offset).limit(@limit))
        next
      end

      # if the records array is not full yet it means that previous
      # scope was too small. Now we are trying to fill it up using next scopes
      # Please note that we start with offset 0 as we are just adding missing records from the next scope
      if records.present? && records.length < @limit
        records_remaining = @limit - records.length
        records.push(*scope.offset(0).limit(records_remaining))
      end
    end
  end

  # The essence of pagination is get a sublist (subarray) of the long array of records.
  # The problem here is, we are paginating through different database scopes
  # This method calculates start and end index of each scope. This will be used later to get
  # proper records.
  # Empty scopes get nil instead of range
  #
  # Eg.
  # If we have 2 schools records, 3 private childcare provider records and 1 local authority to paginate,
  # the result will look like that:
  # {
  #   School::ActiveRecord_Relation=>0...2,
  #   PrivateChildcareProvider::ActiveRecord_Relation=>2...5,
  #   LocalAuthority::ActiveRecord_Relation=>5...6}
  # }
  def calculate_scopes_indexes
    @scope_indexes = {}
    start_index = 0

    scopes.each do |scope|
      if scope.empty?
        @scope_indexes[scope.class] = nil
        next
      end
      end_index = scope.length + start_index
      @scope_indexes[scope.class] = (start_index...end_index)

      start_index = end_index
    end
    @scope_indexes
  end
end
