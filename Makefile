TERRAFILE_VERSION=0.8
ARM_TEMPLATE_TAG=1.1.6
RG_TAGS={"Product" : "Register for National Professional Qualifications (NPQ)"}
REGION=UK South
SERVICE_NAME=npq-registration
SERVICE_SHORT=cpdnpq

help:
	@grep -E '^[a-zA-Z\._\-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

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

.PHONY: review
review: test-cluster ## Specify review AKS environment
	# PULL_REQUEST_NUMBER is set by the GitHub action
	$(if $(PULL_REQUEST_NUMBER), , $(error Missing environment variable "PULL_REQUEST_NUMBER"))
	$(eval include global_config/review.sh)
	$(eval export TF_VAR_pull_request_number=-$(PULL_REQUEST_NUMBER))

.PHONY: staging
staging: test-cluster
	$(eval include global_config/staging.sh)

sandbox: production-cluster
	$(eval include global_config/sandbox.sh)

migration: production-cluster
	$(eval include global_config/migration.sh)

production: production-cluster
	$(if $(or ${SKIP_CONFIRM}, ${CONFIRM_PRODUCTION}), , $(error Missing CONFIRM_PRODUCTION=yes))
	$(eval include global_config/production.sh)

domains:
	$(eval include global_config/domains.sh)

domains-composed-variables:
	$(eval RESOURCE_GROUP_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}domains-rg)
	$(eval KEYVAULT_NAMES=["${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}domains-kv"])
	$(eval STORAGE_ACCOUNT_NAME=${AZURE_RESOURCE_PREFIX}${SERVICE_SHORT}domainstf)

composed-variables:
	$(eval RESOURCE_GROUP_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-rg)
	$(eval KEYVAULT_NAMES='("${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-app-kv", "${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-inf-kv")')
	$(eval STORAGE_ACCOUNT_NAME=${AZURE_RESOURCE_PREFIX}${SERVICE_SHORT}${CONFIG_SHORT}tfsa)
	$(eval LOG_ANALYTICS_WORKSPACE_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-log)

ci:
	$(eval AUTO_APPROVE=-auto-approve)
	$(eval SKIP_AZURE_LOGIN=true)
	$(eval SKIP_CONFIRM=true)

bin/terrafile: ## Install terrafile to manage terraform modules
	curl -sL https://github.com/coretech/terrafile/releases/download/v${TERRAFILE_VERSION}/terrafile_${TERRAFILE_VERSION}_$$(uname)_x86_64.tar.gz \
		| tar xz -C ./bin terrafile

set-azure-account:
	[ "${SKIP_AZURE_LOGIN}" != "true" ] && az account set -s ${AZURE_SUBSCRIPTION} || true

terraform-init: composed-variables bin/terrafile set-azure-account
	$(if $(DOCKER_IMAGE), , $(error Missing environment variable "DOCKER_IMAGE"))
	$(if $(PULL_REQUEST_NUMBER), $(eval KEY_PREFIX=$(PULL_REQUEST_NUMBER)), $(eval KEY_PREFIX=$(ENVIRONMENT)))

	./bin/terrafile -p terraform/application/vendor/modules -f terraform/application/config/$(CONFIG)_Terrafile
	terraform -chdir=terraform/application init -upgrade -reconfigure \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=${KEY_PREFIX}.tfstate

	$(eval export TF_VAR_azure_resource_prefix=${AZURE_RESOURCE_PREFIX})
	$(eval export TF_VAR_config_short=${CONFIG_SHORT})
	$(eval export TF_VAR_service_name=${SERVICE_NAME})
	$(eval export TF_VAR_service_short=${SERVICE_SHORT})
	$(eval export TF_VAR_docker_image=$(DOCKER_IMAGE))

terraform-plan: terraform-init
	terraform -chdir=terraform/application plan -var-file "config/${CONFIG}.tfvars.json"

terraform-apply: terraform-init
	terraform -chdir=terraform/application apply -var-file "config/${CONFIG}.tfvars.json" ${AUTO_APPROVE}

## DOCKER_IMAGE=fake-image make review terraform-unlock PULL_REQUEST_NUMBER=4169 LOCK_ID=123456
## DOCKER_IMAGE=fake-image make staging terraform-unlock LOCK_ID=123456
.PHONY: terraform-unlock
terraform-unlock: terraform-init
	terraform -chdir=terraform/application force-unlock ${LOCK_ID}

.PHONY: terraform-destroy
terraform-destroy: terraform-init
	terraform -chdir=terraform/application destroy -var-file "config/${CONFIG}.tfvars.json" ${AUTO_APPROVE}

set-what-if:
	$(eval WHAT_IF=--what-if)

arm-deployment: composed-variables set-azure-account
	$(if ${DISABLE_KEYVAULTS},, $(eval KV_ARG=keyVaultNames=${KEYVAULT_NAMES}))
	$(if ${ENABLE_KV_DIAGNOSTICS}, $(eval KV_DIAG_ARG=enableDiagnostics=${ENABLE_KV_DIAGNOSTICS} logAnalyticsWorkspaceName=${LOG_ANALYTICS_WORKSPACE_NAME}),)

	az deployment sub create --name "resourcedeploy-tsc-$(shell date +%Y%m%d%H%M%S)" \
		-l "${REGION}" --template-uri "https://raw.githubusercontent.com/DFE-Digital/tra-shared-services/${ARM_TEMPLATE_TAG}/azure/resourcedeploy.json" \
		--parameters "resourceGroupName=${RESOURCE_GROUP_NAME}" 'tags=${RG_TAGS}' \
		"tfStorageAccountName=${STORAGE_ACCOUNT_NAME}" "tfStorageContainerName=terraform-state" \
		${KV_ARG} \
		${KV_DIAG_ARG} \
		"enableKVPurgeProtection=${KV_PURGE_PROTECTION}" \
		${WHAT_IF}

deploy-domain-arm-resources: domains domains-composed-variables arm-deployment

validate-domain-arm-resources: set-what-if domains domains-composed-variables arm-deployment

deploy-arm-resources: arm-deployment ## Validate ARM resource deployment. Usage: make domains validate-arm-resources

validate-arm-resources: set-what-if arm-deployment ## Validate ARM resource deployment. Usage: make domains validate-arm-resources

domains-infra-init: bin/terrafile domains domains-composed-variables domains set-azure-account
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

test-cluster:
	$(eval CLUSTER_RESOURCE_GROUP_NAME=s189t01-tsc-ts-rg)
	$(eval CLUSTER_NAME=s189t01-tsc-test-aks)

production-cluster:
	$(eval CLUSTER_RESOURCE_GROUP_NAME=s189p01-tsc-pd-rg)
	$(eval CLUSTER_NAME=s189p01-tsc-production-aks)

get-cluster-credentials: set-azure-account
	az aks get-credentials --overwrite-existing -g ${CLUSTER_RESOURCE_GROUP_NAME} -n ${CLUSTER_NAME}
	kubelogin convert-kubeconfig -l $(if ${GITHUB_ACTIONS},spn,azurecli)

.PHONY: install-konduit
install-konduit: ## Install the konduit script, for accessing backend services
	[ ! -f bin/konduit.sh ] \
		&& curl -s https://raw.githubusercontent.com/DFE-Digital/teacher-services-cloud/master/scripts/konduit.sh -o bin/konduit.sh \
		&& chmod +x bin/konduit.sh \
		|| true

aks-console: get-cluster-credentials
	$(if $(PULL_REQUEST_NUMBER), $(eval export APP_ID=review-$(PULL_REQUEST_NUMBER)) , $(eval export APP_ID=$(CONFIG_LONG)))
	kubectl -n ${NAMESPACE} exec -ti --tty deployment/npq-registration-${APP_ID}-web -- /bin/sh -c "cd /app && bundle exec rails c"

aks-ssh: get-cluster-credentials
	$(if $(PULL_REQUEST_NUMBER), $(eval export APP_ID=review-$(PULL_REQUEST_NUMBER)) , $(eval export APP_ID=$(CONFIG_LONG)))
	kubectl -n ${NAMESPACE} exec -ti --tty deployment/npq-registration-${APP_ID}-web -- /bin/sh

action-group-resources: set-azure-account # make env_aks action-group-resources ACTION_GROUP_EMAIL=notificationemail@domain.com . Must be run before setting enable_monitoring=true for each subscription
	$(if $(ACTION_GROUP_EMAIL), , $(error Please specify a notification email for the action group))
	echo ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-mn-rg
	az group create -l uksouth -g ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-mn-rg --tags "Product=Register for National Professional Qualifications (NPQ)" "Environment=Test" "Service Offering=Teacher services cloud"
	az monitor action-group create -n ${AZURE_RESOURCE_PREFIX}-npq-registration -g ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-mn-rg --short-name ${AZURE_RESOURCE_PREFIX}-npq --action email ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-email ${ACTION_GROUP_EMAIL}

# Removes explicit postgres database URLs from database.yml
konduit-cleanup:
	sed -i '' -e '/url\: "postgres/d' config/database.yml; \
	exit 0

define KONDUIT_CONNECT
	trap 'make konduit-cleanup' INT; \
	tmp_file=$$(mktemp); \
	$(MAKE) konduit-cleanup; \
	{ \
		(tail -f -n0 "$$tmp_file" & ) | grep -q "postgres://"; \
		postgres_url=$$(grep -o 'postgres://[^ ]*' "$$tmp_file"); \
		echo "$$postgres_url"; \
		sed -i '' -e "s|npq_registration_development|&\\n    url: \"$$postgres_url\"|g" config/database.yml; \
	} & \
	bin/konduit.sh -d
endef

# Creates a konduit to the DB and points development to it. The konduit URL is removed when the konduit is closed.
konduit: get-cluster-credentials
	$(KONDUIT_CONNECT) ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-pg -n ${NAMESPACE} -k ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-app-kv cpd-ecf-${CONFIG_LONG}-web -- psql > "$$tmp_file"
	exit 0

# Creates a konduit to the snapshot DB and points development to it. The konduit URL is removed when the konduit is closed.
konduit-snapshot: get-cluster-credentials
	$(KONDUIT_CONNECT) ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-pg-snapshot -n ${NAMESPACE} -k ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-app-kv cpd-ecf-${CONFIG_LONG}-web -- psql > "$$tmp_file"
	exit 0

define SET_APP_ID_FROM_PULL_REQUEST_NUMBER
	$(if $(PULL_REQUEST_NUMBER), $(eval export APP_ID=review-$(PULL_REQUEST_NUMBER)) , $(eval export APP_ID=$(CONFIG_LONG)))
endef

# downloads the given file from the app/tmp directory of all
# pods in the cluster to the local computer (in a subdirectory matching the pod name).
## ie: FILENAME=restart.txt make staging aks-download-tmp-file
## ie: FILENAME=restart.txt make ci production aks-download-tmp-file
aks-download-tmp-file: get-cluster-credentials
	$(SET_APP_ID_FROM_PULL_REQUEST_NUMBER)
	$(if $(FILENAME), , $(error Usage: FILENAME=restart.txt make staging aks-download-tmp-file))
	kubectl get pods -n ${NAMESPACE} -l app=npq-registration-${APP_ID}-web -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | xargs -I {} sh -c 'mkdir -p {}/ && kubectl cp ${NAMESPACE}/{}:/app/tmp/${FILENAME} {}/${FILENAME}'

# uploads the given file to the app/tmp directory of all
# pods in the cluster.
## ie: FILENAME=local_file.txt make staging aks-upload-tmp-file
aks-upload-tmp-file: get-cluster-credentials
	$(SET_APP_ID_FROM_PULL_REQUEST_NUMBER)
	$(if $(FILENAME), , $(error Usage: FILENAME=restart.txt make staging aks-upload-tmp-file))
	kubectl get pods -n ${NAMESPACE} -l app=npq-registration-${APP_ID}-web -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | xargs -I {} kubectl cp ${FILENAME} ${NAMESPACE}/{}:/app/tmp/${FILENAME}
