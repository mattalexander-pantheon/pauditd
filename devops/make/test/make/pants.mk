APP=common-make-pants

include common.mk
# Override normal logic so that we don't kill a developer's personal sandbox when running locally.
KUBE_NAMESPACE := sandbox-cm-$(BRANCH)
include common-kube.mk
# Choose just one service so we can finish faster.
PANTS_INCLUDE := metrics
PANTS_SANDBOX_NAME := $(KUBE_NAMESPACE)
include common-pants.mk

test-common-pants: install-circle-pants init-circle-pants
