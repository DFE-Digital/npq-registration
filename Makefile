.PHONY: build-local-image docker-compose-build
build-local-image:
	docker buildx build -t dfedigital/govuk-rails-boilerplate:builder-local \
		--cache-from dfedigital/govuk-rails-boilerplate:builder-local \
		--target builder \
		.
	docker buildx build -t dfedigital/govuk-rails-boilerplate:local \
		--cache-from dfedigital/govuk-rails-boilerplate:builder-local \
		--cache-from dfedigital/govuk-rails-boilerplate:local \
		.

docker-compose-build:
	docker-compose build --build-arg BUNDLE_FLAGS='--jobs=4 --no-binstubs --no-cache' --parallel
