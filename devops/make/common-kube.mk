# Common kube things. This is the simplest set of common kube tasks
#
# INPUT VARIABLES
#  - APP: should be defined in your topmost Makefile
#  - SECRET_FILES: list of files that should exist in secrets/* used by
#                  _validate_secrets task
#
# EXPORT VARIABLES
#   - KUBE_NAMESPACE: represents the kube namespace that has been detected based on
#              branch build and circle existence.
#   - KUBE_CONTEXT: set this variable to whatever kubectl reports as the default
#                   context
#   - KUBECTL_CMD: sets up cubectl with the namespace + context for easy usage
#                  in top level make files
#-------------------------------------------------------------------------------

## Append tasks to the global tasks
deps-circle:: deps-circle-kube
lint:: lint-kubeval

# Use the same script used to look up values in setup-gcloud.sh
# NOTE: using `@` makes reuse and assignment wonky, using `define` looks wonky because the indentation is included in the expansion of `$(call)`
KUBE_CONTEXT_EXPAND = $(shell devops/make/sh/cluster-vars.sh $(1) | awk -F '=' '/CLUSTER_LONG_NAME/ { print $$2 }')

ifdef CLUSTER_DEFAULT
	KUBE_CONTEXT ?= $(call KUBE_CONTEXT_EXPAND,$(CLUSTER_DEFAULT))
endif

# Use pants to divine the namespace on local development, if unspecified.
ifndef CIRCLECI
  KUBE_NAMESPACE ?= $(shell pants config get default-sandbox-name 2> /dev/null)
endif

# use cases:
#  all default - NS/context aren't specified from caller
#    - master branch
#       ->  CONTEXT =  DEFAULT_CLUSTER ()
#       ->  NAMESPACE = PROD
#    - non master branch
#      -> CONTEXT = DEFAULT_SANDBOX_CTX
#      -> NAMESPACE = SANDBOX_NS
#
#  JUST NS specified
#    - master
#      -> CONTEXT = DEFAULT_CLUSTER
#      -> NAMESPACE = USER_SPECIFIED_NS
#    - non master
#      -> CONTEXT = DEFAULT_SANDBOX_CTX
#      -> NAMESPACE = USER_SPECIFIED_NS
#
#  JUST Context
#    - master
#      -> CONTEXT = USER_SPECIFIED_CTX
#      -> NAMESPACE = PROD
#    - non master
#      -> CONTEXT = USER_SPECIFIED_CTX
#      -> NAMESPACE = SANDBOX_NS
#
#  BOTH... Obvious take USER_SPECIFIED_*

# default kube context based on above rules
ifndef KUBE_CONTEXT
  KUBE_CONTEXT := gke_pantheon-sandbox_us-central1_sandbox-01

  ifeq ($(BRANCH), master) # prod
    KUBE_CONTEXT := gke_pantheon-internal_us-central1-b_cluster-01
  endif
endif

# If we are on master branch, use production kube env (unless KUBE_NAMESPACE is already set in the environment)based on above rules
# see cases above
ifndef KUBE_NAMESPACE
  # If on circle and not on master, build into a sandbox environment.
  KUBE_NAMESPACE := sandbox-$(APP)-$(BRANCH)

  ifeq ($(BRANCH), master) # prod
    KUBE_NAMESPACE := production
  endif
endif

ifndef UPDATE_GCLOUD
  UPDATE_GCLOUD := true
endif

# template-sandbox lives in sandbox-02, force it to always use that cluster
ifeq ($(KUBE_NAMESPACE), template-sandbox)
  KUBE_CONTEXT := gke_pantheon-sandbox_us-east4_sandbox-02
endif

KUBECTL_CMD=kubectl --namespace=$(KUBE_NAMESPACE) --context=$(KUBE_CONTEXT)

# extend or define circle deps to install gcloud
ifeq ($(UPDATE_GCLOUD), true)
  deps-circle-kube:: install-update-kube setup-kube
else
  deps-circle-kube:: setup-kube
endif

install-update-kube::
	$(call INFO, "updating or install gcloud cli")
	@if command -v gcloud >/dev/null; then \
		./devops/make/sh/update-gcloud.sh > /dev/null ; \
	else  \
		./devops/make/sh/install-gcloud.sh > /dev/null ; \
	fi

setup-kube::
	$(call INFO, "setting up gcloud cli")
	@./devops/make/sh/setup-gcloud.sh

update-secrets:: ## update secret volumes in a kubernetes cluster
	$(call INFO, "updating secrets for $(KUBE_NAMESPACE) in $(KUBE_CONTEXT)")
	@APP=$(APP) KUBE_NAMESPACE=$(KUBE_NAMESPACE) KUBE_CONTEXT=$(KUBE_CONTEXT) \
		./devops/make/sh/update-kube-object.sh ./devops/k8s/secrets > /dev/null

update-configmaps:: ## update configmaps in a kubernetes cluster
	$(call INFO, "updating configmaps for $(KUBE_NAMESPACE) in $(KUBE_CONTEXT)")
	@APP=$(APP) KUBE_NAMESPACE=$(KUBE_NAMESPACE) KUBE_CONTEXT=$(KUBE_CONTEXT) \
		./devops/make/sh/update-kube-object.sh ./devops/k8s/configmaps

# set SECRET_FILES to a list, and this will ensure they are there
_validate-secrets::
		@for j in $(SECRET_FILES) ; do \
			if [ ! -e secrets/$$j ] ; then  \
			echo "Missing file: secrets/$$j" ;\
				exit 1 ;  \
			fi \
		done

YAMLS := $(shell find . -path './devops/k8s/*' -not -path './devops/k8s/configmaps/*' \( -name '*.yaml' -or -name '*.yml' \))
lint-kubeval:: ## validate kube yamls
ifneq (, $(shell which kubeval))
  ifdef YAMLS
	$(call INFO, "running kubeval for $(YAMLS)")
	kubeval --strict $(YAMLS)
  endif
endif

.PHONY::  deps-circle force-pod-restart
