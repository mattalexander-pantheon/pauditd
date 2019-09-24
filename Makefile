APP:=pauditd
PANTS_INCLUDE := $(APP)
PROJECT := $$GOOGLE_PROJECT

include devops/make/common.mk
include devops/make/common-go.mk
include devops/make/common-kube.mk
include devops/make/common-pants.mk
include devops/make/common-docker.mk

deploy: push-circle update-configmaps update-daemonset update-sa

update-daemonset:
	$(call INFO, "Deploying Daemonset for pauditd with image: $(IMAGE) to namespace: $(KUBE_NAMESPACE)")
	@sed -e "s#__KUBE_NAMESPACE__#$(KUBE_NAMESPACE)#" \
	    -e "s#__IMAGE__#$(IMAGE)#" \
		devops/k8s/daemonset.yaml \
		| $(KUBECTL_CMD) apply -f -

update-sa:
	$(call INFO, "Deploying ServiceAccount for pauditd to namespace: $(KUBE_NAMESPACE)")
	@$(KUBECTL_CMD) apply -f devops/k8s/sa.yaml

generate-non-prod-cert:
	@mkdir -p ./devops/k8s/secrets/non-prod/certs
	@CN=pauditd \
		OU=pauditd \
		DIRECTORY=./devops/k8s/secrets/non-prod/certs \
		USE_ONEBOX_CA=true \
		FILENAME=pauditd \
		bash ./devops/make/sh/create-tls-cert.sh

PHONY: deploy deploy-sa
