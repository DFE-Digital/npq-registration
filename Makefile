ARM_TEMPLATE_TAG=1.1.10
RG_TAGS={"Product" : "Teacher Training Entitlement"}
REGION=UK South
SERVICE_NAME=teacher-training-entitlement
SERVICE_SHORT=cpdtte
DOCKER_REPOSITORY=ghcr.io/dfe-digital/teacher-training-entitlement

# Handle BSD and GNU sed differences
SED_INPLACE ?= $(shell if sed --version >/dev/null 2>&1; then echo "-i"; else echo "-i ''"; fi)

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

.PHONY: development
development: test-cluster
	$(eval include global_config/development.sh)

.PHONY: review
review: test-cluster ## Specify review configuration
	$(if ${PR_NUMBER},,$(error Missing PR_NUMBER))
	$(eval ENVIRONMENT=pr-${PR_NUMBER})
	$(eval include global_config/review.sh)
	$(eval TERRAFORM_BACKEND_KEY=terraform-$(PR_NUMBER).tfstate)
	$(eval export TF_VAR_app_suffix=-$(PR_NUMBER))

.PHONY: staging
staging: test-cluster
	$(eval include global_config/staging.sh)

sandbox: production-cluster
	$(eval include global_config/sandbox.sh)

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

smoke-test:
	$(eval URL=$(shell cd terraform/application && terraform output -raw url))
	$(eval SHA=$(if $(DEPLOY_COMMIT_SHA),$(DEPLOY_COMMIT_SHA),$(shell git rev-parse HEAD)))
	bin/smoke ${URL} ${SHA}

set-azure-account:
	[ "${SKIP_AZURE_LOGIN}" != "true" ] && az account set -s ${AZURE_SUBSCRIPTION} || true

terraform-init: composed-variables set-azure-account
	$(if $(DOCKER_IMAGE_TAG), , $(eval DOCKER_IMAGE_TAG=main))
	$(if $(PR_NUMBER), $(eval KEY_PREFIX=$(PR_NUMBER)), $(eval KEY_PREFIX=$(ENVIRONMENT)))

	rm -rf terraform/application/vendor/modules/aks
	git -c advice.detachedHead=false clone --depth=1 --single-branch --branch ${TERRAFORM_MODULES_TAG} https://github.com/DFE-Digital/terraform-modules.git terraform/application/vendor/modules/aks

	terraform -chdir=terraform/application init -upgrade -reconfigure \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=${KEY_PREFIX}.tfstate

	$(eval export TF_VAR_azure_resource_prefix=${AZURE_RESOURCE_PREFIX})
	$(eval export TF_VAR_config_short=${CONFIG_SHORT})
	$(eval export TF_VAR_config=${CONFIG})
	$(eval export TF_VAR_service_name=${SERVICE_NAME})
	$(eval export TF_VAR_service_short=${SERVICE_SHORT})
	$(eval export TF_VAR_docker_image=${DOCKER_REPOSITORY}:${DOCKER_IMAGE_TAG})

terraform-plan: terraform-init
	terraform -chdir=terraform/application plan -var-file "config/${CONFIG}.tfvars.json"

terraform-apply: terraform-init
	terraform -chdir=terraform/application apply -var-file "config/${CONFIG}.tfvars.json" ${AUTO_APPROVE}

## DOCKER_IMAGE=fake-image make review terraform-unlock PR_NUMBER=4169 LOCK_ID=123456
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

deploy-arm-resources: arm-deployment

validate-arm-resources: set-what-if arm-deployment

domains-infra-init: domains domains-composed-variables domains set-azure-account
	rm -rf terraform/domains/infrastructure/vendor/modules/domains
	git -c advice.detachedHead=false clone --depth=1 --single-branch --branch ${TERRAFORM_MODULES_TAG} https://github.com/DFE-Digital/terraform-modules.git terraform/domains/infrastructure/vendor/modules/domains

	terraform -chdir=terraform/domains/infrastructure init -reconfigure -upgrade \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=domains_infrastructure.tfstate

domains-infra-plan: domains domains-infra-init
	terraform -chdir=terraform/domains/infrastructure plan -var-file config/zones.tfvars.json

domains-infra-apply: domains domains-infra-init
	terraform -chdir=terraform/domains/infrastructure apply -var-file config/zones.tfvars.json ${AUTO_APPROVE}

domains-init: domains domains-composed-variables set-azure-account
	rm -rf terraform/domains/environment_domains/vendor/modules/domains
	git -c advice.detachedHead=false clone --depth=1 --single-branch --branch ${TERRAFORM_MODULES_TAG} https://github.com/DFE-Digital/terraform-modules.git terraform/domains/environment_domains/vendor/modules/domains

	terraform -chdir=terraform/domains/environment_domains init -upgrade -reconfigure \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=${ENVIRONMENT}.tfstate

domains-plan: domains-init  ## Terraform plan for DNS environment domains. Usage: make development domains-plan
	terraform -chdir=terraform/domains/environment_domains plan -var-file config/${CONFIG}.tfvars.json

domains-apply: domains-init ## Terraform apply for DNS environment domains. Usage: make development domains-apply
	terraform -chdir=terraform/domains/environment_domains apply -var-file config/${CONFIG}.tfvars.json ${AUTO_APPROVE}

test-cluster:
	$(eval CLUSTER_RESOURCE_GROUP_NAME=s189t01-tsc-ts-rg)
	$(eval CLUSTER_NAME=s189t01-tsc-test-aks)

production-cluster:
	$(eval CLUSTER_RESOURCE_GROUP_NAME=s189p01-tsc-pd-rg)
	$(eval CLUSTER_NAME=s189p01-tsc-production-aks)

get-cluster-credentials: set-azure-account
	az aks get-credentials --overwrite-existing -g ${CLUSTER_RESOURCE_GROUP_NAME} -n ${CLUSTER_NAME}
	kubelogin convert-kubeconfig -l $(if ${AAD_LOGIN_METHOD},${AAD_LOGIN_METHOD},azurecli)

.PHONY: install-konduit
install-konduit: ## Install the konduit script, for accessing backend services
	[ ! -f bin/konduit.sh ] \
		&& curl -s https://raw.githubusercontent.com/DFE-Digital/teacher-services-cloud/master/scripts/konduit.sh -o bin/konduit.sh \
		&& chmod +x bin/konduit.sh \
		|| true

aks-console: get-cluster-credentials
	$(if $(PR_NUMBER), $(eval export APP_ID=review-$(PR_NUMBER)) , $(eval export APP_ID=$(CONFIG_LONG)))
	kubectl -n ${NAMESPACE} exec -ti --tty deployment/teacher-training-entitlement-${APP_ID}-worker -- /bin/sh -c "cd /app && bundle exec rails c --sandbox"

aks-rw-console: get-cluster-credentials
	$(if $(PR_NUMBER), $(eval export APP_ID=review-$(PR_NUMBER)) , $(eval export APP_ID=$(CONFIG_LONG)))
	kubectl -n ${NAMESPACE} exec -ti --tty deployment/teacher-training-entitlement-${APP_ID}-worker -- /bin/sh -c "cd /app && bundle exec rails c"

aks-runner: get-cluster-credentials
	$(if $(PR_NUMBER), $(eval export APP_ID=review-$(PR_NUMBER)) , $(eval export APP_ID=$(CONFIG_LONG)))
	kubectl -n ${NAMESPACE} exec -ti --tty deployment/teacher-training-entitlement-${APP_ID}-worker -- /bin/sh -c "cd /app && bundle exec rails runner \"$(code)\""

aks-ssh: get-cluster-credentials
	$(if $(PR_NUMBER), $(eval export APP_ID=review-$(PR_NUMBER)) , $(eval export APP_ID=$(CONFIG_LONG)))
	kubectl -n ${NAMESPACE} exec -ti --tty deployment/teacher-training-entitlement-${APP_ID}-worker -- /bin/sh

aks-web-ssh: get-cluster-credentials
	$(if $(PR_NUMBER), $(eval export APP_ID=review-$(PR_NUMBER)) , $(eval export APP_ID=$(CONFIG_LONG)))
	kubectl -n ${NAMESPACE} exec -ti --tty deployment/teacher-training-entitlement-${APP_ID} -- /bin/sh

action-group: set-azure-account # make production action-group ACTION_GROUP_EMAIL=notificationemail@domain.com . Must be run before setting enable_monitoring=true. Use any non-prod environment to create in the test subscription.
	$(if $(ACTION_GROUP_EMAIL), , $(error Please specify a notification email for the action group))
	az group create -l uksouth -g ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-mn-rg --tags "Product=${SERVICE_NAME}"
	az monitor action-group create -n ${AZURE_RESOURCE_PREFIX}-${SERVICE_NAME} -g ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-mn-rg --action email ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-email ${ACTION_GROUP_EMAIL}

# Removes explicit postgres database URLs from database.yml
# konduit-cleanup:
#	sed $(SED_INPLACE) -e '/url\: "postgres/d' config/database.yml; \
#	exit 0

define KONDUIT_CONNECT
	trap 'make konduit-cleanup' INT; \
	tmp_file=$$(mktemp); \
	$(MAKE) konduit-cleanup; \
	{ \
		(tail -f -n0 "$$tmp_file" & ) | grep -q "postgres://"; \
		postgres_url=$$(grep -o 'postgres://[^ ]*' "$$tmp_file"); \
		echo "$$postgres_url"; \
		sed $(SED_INPLACE) -e "s|cpd_tte_development|&\\n  url: \"$$postgres_url\"|g" config/database.yml; \
	} & \
	bin/konduit.sh -d
endef

# Creates a konduit to the DB and points development to it. The konduit URL is removed when the konduit is closed.
konduit: get-cluster-credentials
	$(KONDUIT_CONNECT) ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-pg -n ${NAMESPACE} -k ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-app-kv teacher-training-entitlement-${CONFIG_LONG}-web -- psql > "$$tmp_file"
	exit 0

# Creates a konduit to the snapshot DB and points development to it. The konduit URL is removed when the konduit is closed.
konduit-snapshot: get-cluster-credentials
	$(KONDUIT_CONNECT) ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-pg-snapshot -n ${NAMESPACE} -k ${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-app-kv teacher-training-entitlement-${CONFIG_LONG}-web -- psql > "$$tmp_file"
	exit 0

define SET_APP_ID_FROM_PR_NUMBER
	$(if $(PR_NUMBER), $(eval export APP_ID=review-$(PR_NUMBER)) , $(eval export APP_ID=$(CONFIG_LONG)))
endef

# downloads the given file from the app/tmp directory of all
# pods in the cluster to the local computer (in a subdirectory matching the pod name).
## ie: FILENAME=restart.txt make staging aks-download-tmp-file
## ie: FILENAME=restart.txt make ci production aks-download-tmp-file
aks-download-tmp-file: get-cluster-credentials
	$(SET_APP_ID_FROM_PR_NUMBER)
	$(if $(FILENAME), , $(error Usage: FILENAME=restart.txt make staging aks-download-tmp-file))
	kubectl get pods -n ${NAMESPACE} -l app=teacher-training-entitlement-${APP_ID}-worker -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | xargs -I {} sh -c 'mkdir -p {}/ && kubectl cp ${NAMESPACE}/{}:/app/tmp/${FILENAME} {}/${FILENAME}'

# uploads the given file to the app/tmp directory of all
# pods in the cluster.
## ie: FILENAME=local_file.txt make staging aks-upload-tmp-file
aks-upload-tmp-file: get-cluster-credentials
	$(SET_APP_ID_FROM_PR_NUMBER)
	$(if $(FILENAME), , $(error Usage: FILENAME=restart.txt make staging aks-upload-tmp-file))
	kubectl get pods -n ${NAMESPACE} -l app=teacher-training-entitlement-${APP_ID}-worker -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | xargs -I {} kubectl cp ${FILENAME} ${NAMESPACE}/{}:/app/tmp/${FILENAME}

maintenance-image-push: ## Build and push maintenance page image: make production maintenance-image-push GITHUB_TOKEN=x [MAINTENANCE_IMAGE_TAG=y]
	$(if ${GITHUB_TOKEN},, $(error Provide a valid Github token with write:packages permissions as GITHUB_TOKEN variable))
	$(if ${MAINTENANCE_IMAGE_TAG},, $(eval export MAINTENANCE_IMAGE_TAG=$(shell date +%s)))
	docker build -t ghcr.io/dfe-digital/teacher-training-entitlement-maintenance:${MAINTENANCE_IMAGE_TAG} maintenance_page
	echo ${GITHUB_TOKEN} | docker login ghcr.io -u USERNAME --password-stdin
	docker push ghcr.io/dfe-digital/teacher-training-entitlement-maintenance:${MAINTENANCE_IMAGE_TAG}

maintenance-fail-over: get-cluster-credentials ## Fail main app over to the maintenance page. Requires an existing maintenance docker image: make production maintenance-fail-over MAINTENANCE_IMAGE_TAG=y. See https://github.com/DFE-Digital/teacher-services-cloud/blob/main/documentation/maintenance-page.md#github-token
	$(eval export CONFIG)
	./maintenance_page/scripts/failover.sh

enable-maintenance: maintenance-image-push maintenance-fail-over ## Build, push, fail over: make production enable-maintenance GITHUB_TOKEN=x [MAINTENANCE_IMAGE_TAG=y]

disable-maintenance: get-cluster-credentials ## Fail back to the main app: make production disable-maintenance
	$(eval export CONFIG)
	./maintenance_page/scripts/failback.sh

db-seed: get-cluster-credentials # Example db seed for review apps, modify as required
	$(if $(PR_NUMBER), , $(error can only run with PR_NUMBER))
	$(eval NAMESPACE=$(shell jq -r '.namespace' terraform/application/config/$(CONFIG).tfvars.json))
	kubectl -n ${NAMESPACE} exec deployment/${SERVICE_NAME}-review-${PR_NUMBER} -- /bin/sh -c "cd /app && bundle exec rake db:seed"

set-pgserver:
	$(eval SERVERNAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-pg)

list-pglogs: composed-variables set-pgserver set-azure-account
	az postgres flexible-server server-logs list --resource-group ${RESOURCE_GROUP_NAME} --server-name ${SERVERNAME}

download-pglogs: composed-variables set-pgserver set-azure-account
	$(if $(LOG_NAME), , $(error Please specify a LOG_NAME for download))
	az postgres flexible-server server-logs download --name ${LOG_NAME} --resource-group ${RESOURCE_GROUP_NAME} --server-name ${SERVERNAME}
	ls -l $(LOG_NAME)*

enable-pglogs: composed-variables set-pgserver set-azure-account
	echo "Enabling server logs for PostgreSQL server ${SERVERNAME}"
	echo "Current Value"
	az postgres flexible-server parameter show --resource-group ${RESOURCE_GROUP_NAME} --server-name ${SERVERNAME} --name logfiles.download_enable --query value
	echo "Setting Value"
	az postgres flexible-server parameter set --resource-group ${RESOURCE_GROUP_NAME} --server-name ${SERVERNAME} --name logfiles.download_enable --value on
	echo "New Value"
	az postgres flexible-server parameter show --resource-group ${RESOURCE_GROUP_NAME} --server-name ${SERVERNAME} --name logfiles.download_enable --query value

disable-pglogs: composed-variables set-pgserver set-azure-account
	echo "Current Value"
	az postgres flexible-server parameter show --resource-group ${RESOURCE_GROUP_NAME} --server-name ${SERVERNAME} --name logfiles.download_enable --query value
	echo "Setting Value"
	az postgres flexible-server parameter set --resource-group ${RESOURCE_GROUP_NAME} --server-name ${SERVERNAME} --name logfiles.download_enable --value off
	echo "New Value"
	az postgres flexible-server parameter show --resource-group ${RESOURCE_GROUP_NAME} --server-name ${SERVERNAME} --name logfiles.download_enable --query value

show-service: get-cluster-credentials
	$(if $(PR_NUMBER), $(eval export DSUFFIX="-pr-${PR_NUMBER}"), $(eval export DSUFFIX="-${CONFIG}") )
	$(eval NAMESPACE=$(shell jq -r '.namespace' terraform/application/config/$(CONFIG).tfvars.json))
	echo "Show service deployments"
	kubectl -n ${NAMESPACE} get deployment/${SERVICE_NAME}${DSUFFIX}
	kubectl -n ${NAMESPACE} get deployment/${SERVICE_NAME}${DSUFFIX}-worker

scale-app: get-cluster-credentials
	$(if $(PR_NUMBER), $(eval export DSUFFIX="-pr-${PR_NUMBER}"), $(eval export DSUFFIX="-${CONFIG}") )
	$(if $(REPLICAS),,$(error Missing REPLICAS))
	$(eval NAMESPACE=$(shell jq -r '.namespace' terraform/application/config/$(CONFIG).tfvars.json))
	echo "Scaling app to ${REPLICAS}"
	kubectl -n ${NAMESPACE} scale deployment/${SERVICE_NAME}${DSUFFIX} --replicas ${REPLICAS}

scale-worker: get-cluster-credentials
	$(if $(PR_NUMBER), $(eval export DSUFFIX="-pr-${PR_NUMBER}"), $(eval export DSUFFIX="-${CONFIG}") )
	$(if $(REPLICAS),,$(error Missing REPLICAS))
	$(eval NAMESPACE=$(shell jq -r '.namespace' terraform/application/config/$(CONFIG).tfvars.json))
	echo "Scaling worker to ${REPLICAS}"
	kubectl -n ${NAMESPACE} scale deployment/${SERVICE_NAME}${DSUFFIX}-worker --replicas ${REPLICAS}
