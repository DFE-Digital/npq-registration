TERRAFILE_VERSION=0.8
ARM_TEMPLATE_TAG=1.1.6
RG_TAGS={"Product" : "Teacher services cloud"}
REGION=UK South
SERVICE_NAME=npq-registration
SERVICE_SHORT=cpdnpq

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

production:
	$(if $(or ${SKIP_CONFIRM}, ${CONFIRM_PRODUCTION}), , $(error Missing CONFIRM_PRODUCTION=yes))
	$(eval include global_config/production.sh)

domains:
	$(eval include global_config/domains.sh)

domains-composed-variables:
	$(eval RESOURCE_GROUP_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}domains-rg)
	$(eval KEYVAULT_NAMES=["${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}domains-kv"])
	$(eval STORAGE_ACCOUNT_NAME=${AZURE_RESOURCE_PREFIX}${SERVICE_SHORT}domainstf)

bin/terrafile: ## Install terrafile to manage terraform modules
	curl -sL https://github.com/coretech/terrafile/releases/download/v${TERRAFILE_VERSION}/terrafile_${TERRAFILE_VERSION}_$$(uname)_x86_64.tar.gz \
		| tar xz -C ./bin terrafile

set-azure-account:
	[ "${SKIP_AZURE_LOGIN}" != "true" ] && az account set -s ${AZURE_SUBSCRIPTION} || true

set-what-if:
	$(eval WHAT_IF=--what-if)

arm-deployment: set-azure-account
	$(if ${KEYVAULT_NAMES}, $(eval KV_ARG='keyVaultNames=${KEYVAULT_NAMES}'),)

	az deployment sub create --name "resourcedeploy-tsc-$(shell date +%Y%m%d%H%M%S)" \
		-l "${REGION}" --template-uri "https://raw.githubusercontent.com/DFE-Digital/tra-shared-services/${ARM_TEMPLATE_TAG}/azure/resourcedeploy.json" \
		--parameters "resourceGroupName=${RESOURCE_GROUP_NAME}" 'tags=${RG_TAGS}' \
			"tfStorageAccountName=${STORAGE_ACCOUNT_NAME}" "tfStorageContainerName=terraform-state" \
			${KV_ARG} \
			"enableKVPurgeProtection=${KV_PURGE_PROTECTION}" \
			${WHAT_IF}

deploy-domain-arm-resources: domains-composed-variables arm-deployment

validate-domain-arm-resources: set-what-if domain-composed-variables arm-deployment

domains-infra-init: bin/terrafile domains-composed-variables domains set-azure-account
	./bin/terrafile -p terraform/domains/infrastructure/vendor/modules -f terraform/domains/infrastructure/config/zones_Terrafile

	terraform -chdir=terraform/domains/infrastructure init -reconfigure -upgrade \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=domains_infrastructure.tfstate

domains-infra-plan: domains domains-infra-init
	terraform -chdir=terraform/domains/infrastructure plan -var-file config/zones.tfvars.json

domains-infra-apply: domains domains-infra-init
	terraform -chdir=terraform/domains/infrastructure apply -var-file config/zones.tfvars.json ${AUTO_APPROVE}

domains-init: bin/terrafile domains-composed-variables domains set-azure-account
	./bin/terrafile -p terraform/domains/environment_domains/vendor/modules -f terraform/domains/environment_domains/config/${CONFIG}_Terrafile

	terraform -chdir=terraform/domains/environment_domains init -upgrade -reconfigure \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=${ENVIRONMENT}.tfstate

domains-plan: domains-init
	terraform -chdir=terraform/domains/environment_domains plan -var-file config/${CONFIG}.tfvars.json

domains-apply: domains-init
	terraform -chdir=terraform/domains/environment_domains apply -var-file config/${CONFIG}.tfvars.json ${AUTO_APPROVE}
