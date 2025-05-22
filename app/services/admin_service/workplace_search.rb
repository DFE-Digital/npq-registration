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
    [
      schools_scope,
      private_childcare_provider_scope,
      local_authority_scope,
    ]
  end

  # Return properly paginated scopes
  def find_scopes
    # Extra offset is to compensate for the previous scopes count.
    # When using pagination, we are getting absolute offset. When paginating further scopes, we need to
    # substract offset.
    # Eg:
    # If we already have 24 schools and then 5 PrivateChildcareProviders and we are on the
    # 2rd page, where we will display remaining 4 PCP pagy will set offset to 25.
    # But in this case, we want to display records from offset 1 of the PCP, as one PCP was displayed on the
    # previous page. Using extra_offset will let us do it. In the above case, during accessing the
    # second page, the extra_offset will be set to 24 which will allow us to display records correctly.
    extra_offset = 0
    current_scope_index = 0

    while current_scope_index < scopes.length
      scope = scopes[current_scope_index]

      # case where current scope can be displayed alone
      if scope.count + extra_offset >= @offset + @limit
        return scope.offset(@offset - extra_offset).limit(@limit)
      # case where we need to display more than one different scope in one page
      elsif scope.count + extra_offset > @offset && scope.count + extra_offset < @offset + @limit
        remaining_records_count = (scope.count + extra_offset) % @limit

        records = scope.offset(@offset - extra_offset).limit(remaining_records_count).to_a
        next_scope_index = current_scope_index
        # we need to fill current page with further scopes
        # we iterate until all scopes are looked after or current page records are full
        while (next_scope = scopes[next_scope_index + 1]) && records.count < @limit
          extra_records_count = @limit - records.count
          records += next_scope.offset(0).limit(extra_records_count)
          next_scope_index += 1
        end

        return records
      end

      # If we reached this point it means that current scope is shorter than offset.
      extra_offset += scope.count
      current_scope_index += 1
    end

    [] # Fallback when no records could be found
  end
end
