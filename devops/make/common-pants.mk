# install and configure pants on circle-ci
#
# The following ENV vars must be set before calling this script:
#
#	GITHUB_TOKEN			# Github Personal Access token to read the private repository
#
# Optional:
#	PANTS_VERSION_CONSTRAINT	# Version constraint for pants install to satisfy. Default is "=0.1.10".
#	PANTS_INCLUDE			# Services for pants to include. Default is all.
#	PANTS_EXCLUDE			# Services for pants to exclude. Default is none.
#	PANTS_SANDBOX_NAME		# Name of sandbox. Default is ${APP}-${BUILD_NUM}.
#
FETCH_URL                 ?= "https://github.com/gruntwork-io/fetch/releases/download/v0.1.0/fetch_linux_amd64"
PANTS_VERSION_CONSTRAINT  ?= 0.1.42
PANTS_UPDATE_ONEBOX       ?= false
PANTS_SANDBOX_NAME        ?= $(KUBE_NAMESPACE)
PANTS_SANDBOX_CLUSTER     ?= $(KUBE_CONTEXT)
PANTS_DEBUG               ?= false
PANTS_FLAGS               ?= -s $(PANTS_SANDBOX_NAME) --update-onebox=$(PANTS_UPDATE_ONEBOX) --target-cluster=$(PANTS_SANDBOX_CLUSTER)

ifdef PANTS_INCLUDE
  PANTS_FLAGS += -i $(PANTS_INCLUDE)
endif
ifdef PANTS_EXCLUDE
  PANTS_FLAGS += -e $(PANTS_EXCLUDE)
endif
ifeq ($(PANTS_DEBUG), true)
  PANTS_FLAGS += -d
endif
PANTS_INIT_CMD		:= pants sandbox init   $(PANTS_FLAGS)
PANTS_UPDATE_CMD	:= pants sandbox update $(PANTS_FLAGS)
PANTS_DELETE_CMD	:= pants sandbox delete $(PANTS_FLAGS)

## append to the global task
deps-circle:: create-circle-paths install-circle-pants

create-circle-paths:
	$(shell mkdir -p $$HOME/bin)
	$(shell echo 'export PATH=$$PATH:$$HOME/bin' >> $$BASH_ENV)

install-circle-fetch: create-circle-paths
ifeq (,$(wildcard $(HOME)/bin/fetch ))
	$(call INFO, "installing 'fetch' tool")
	@curl -s -L $(FETCH_URL) -o $(HOME)/bin/fetch > /dev/null
	@chmod 755 $(HOME)/bin/fetch > /dev/null
else
	$(call INFO, "'fetch' tool already installed")
endif

install-circle-pants: install-circle-fetch
ifndef GITHUB_TOKEN
	$(call ERROR, "This task needs a GITHUB_TOKEN environment variable")
endif
	$(call INFO, "Installing pants version satisfying: $(PANTS_VERSION_CONSTRAINT)")
	@fetch --repo="https://github.com/pantheon-systems/pants" \
			--tag=v$(PANTS_VERSION_CONSTRAINT) \
			--release-asset=pants_$(PANTS_VERSION_CONSTRAINT)_linux_amd64.tar.gz \
			--github-oauth-token=$$GITHUB_TOKEN \
			/tmp > /dev/null
	@tar -C $(HOME)/bin -xvzf /tmp/pants_$(PANTS_VERSION_CONSTRAINT)_linux_amd64.tar.gz
	@chmod 755 $(HOME)/bin/pants > /dev/null
	$(call INFO, "Installed pants version" $(shell pants version))

delete-circle-pants:: delete-pants-sandbox ## TODO: remove the alias once $REASONS don't apply

delete-pants-sandbox:: ## deletes pants sandbox
ifneq ($(KUBE_NAMESPACE), production) # prod
	$(call INFO, "Deleting sandbox with command $(PANTS_DELETE_CMD)")
	@$(PANTS_DELETE_CMD) 2> /dev/null
endif

init-circle-pants:: ensure-pants-sandbox
init-circle-pants:: label-ci-ns

# Initializes pants sandbox. Fails if pants can't proceed, eg because the namespace already has deployments.
init-pants-sandbox::
	$(call INFO, "Initializing sandbox \'$(KUBE_NAMESPACE)\' with command \'$(PANTS_INIT_CMD)\'")
	@$(PANTS_INIT_CMD) 2> /dev/null

# Creates the sandbox if it doesn't exist or updates it if it does.
ensure-pants-sandbox::
	$(call INFO, "Using sandbox \'$(KUBE_NAMESPACE)\'.")
	@$(PANTS_INIT_CMD) 2> /dev/null || $(PANTS_UPDATE_CMD) 2> /dev/null

# Labels the sandbox namespace so that garbage collection can delete namespaces
# or PRs that no longer exist.
# Can't keep the whole URL without violating max label length
label-ci-ns:
ifdef CIRCLECI
	$(call INFO, "Adding labels to namespace: $(KUBE_NAMESPACE)")
	@$(KUBECTL_CMD) label --overwrite ns $(KUBE_NAMESPACE) \
			time="$(shell date "+%Y-%m-%d---%H-%M-%S")" \
			repo=$$CIRCLE_PROJECT_REPONAME \
			pr="$(shell echo $$CI_PULL_REQUEST | sed 's/.*\///')" \
			build=$$CIRCLE_BUILD_NUM
endif
