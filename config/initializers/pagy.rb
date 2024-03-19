Pagy::DEFAULT[:size] = [1, 1, 1, 1]
Pagy::DEFAULT[:items] = 25

if Rails.env.test?
  Pagy::DEFAULT[:items] = 5
end
