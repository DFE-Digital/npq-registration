require "pagy/extras/overflow"

Pagy::DEFAULT[:size] = [1, 1, 1, 1]
Pagy::DEFAULT[:items] = 25

if Rails.env.test?
  Pagy::DEFAULT[:items] = 5
end

# Return an empty page when page number too high (other options :last_page and :exception )
Pagy::DEFAULT[:overflow] = :empty_page
