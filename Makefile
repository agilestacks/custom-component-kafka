# Environment variables are set by the Automation Hub before the component gets deployed
# according to the parameters block in hub-component.yaml file
.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= kafka
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= kafka
CHART_VERSION  ?= 0.20.6
REPO           ?= kafka
TIMEOUT        ?= 600
export HELM_HOME ?= $(shell pwd)/.helm

# Since one of the component requirements in the hub-component.yaml is kubernetes,
# the Automation Hub automatically configures Kubernetes config to point to the platform cluster
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

# Called by the Automation Hub when the component is depoyed
deploy: clean init fetch purge install wait

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

fetch:
	$(helm) repo add $(REPO) http://storage.googleapis.com/kubernetes-charts-incubator

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

# Helm is used to install Apache Kafka release
install:
	-$(kubectl) create namespace $(NAMESPACE)
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(REPO)/kafka \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--values values.yaml

wait:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	@echo "Waiting for the zookeeper and kafka replicas to stabilize"
	@while [ `date +%s` -le "$(timeout)" ]; do \
		status=`$(kubectl) -n $(NAMESPACE) get job -o jsonpath='{.items[0].status.succeeded}'`; \
		if [ "$$status" == "1" ]; then \
			echo "done"; \
			exit 0; \
		elif [ "$$status" == "0" ]; then \
			echo "deployment failed"; \
			exit 1; \
		fi; \
		echo "still waiting"; \
		sleep 8; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1

# Called by the Automation Hub when the component is undeployed
undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

clean:
	rm -rf $(HELM_HOME) charts

-include ../Mk/phonies
