#!/bin/bash


AKS_RESOURCE_GROUP='trial'
AKS_CLUSTER_NAME='magento22'
ACR_RESOURCE_GROUP='trial'
ACR_NAME='gonchare'
ACR_PUSH_SERVICE_PRINCIPAL_NAME=acr-push
SUBSCRIPTION_NAME='Free Trial'
SUBSCRIPTION_ID=$(az account show --subscription "$SUBSCRIPTION_NAME" --query "id" --output tsv)
TENANT_ID=$(az account show --subscription "$SUBSCRIPTION_NAME" --query "tenantId" --output tsv)

# Create new cluster
az aks create --name $AKS_CLUSTER_NAME --resource-group trial --disable-rbac --enable-vmss --node-count 1 --generate-ssh-keys --kubernetes-version 1.13.5
# Get the id of the service principal configured for AKS
CLIENT_ID=$(az aks show --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)

# Get the ACR registry resource id
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $ACR_RESOURCE_GROUP --query "id" --output tsv)

# Create role assignment
az role assignment create --assignee $CLIENT_ID --role acrpull --scope $ACR_ID

# Switch context
az aks get-credentials --resource-group trial -n $AKS_CLUSTER_NAME

# Create roles and bindings
kubectl apply -f k8s-config/azure-role-binding.yaml

# Create Services
kubectl create -f k8s-config/svc.yaml

# Create storage class
kubectl apply -f k8s-config/azure-file-sc.yaml

# Create PV
kubectl apply -f k8s-config/azure-file-pvc.yaml


# Obtain the full registry ID for subsequent command args
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)
# Create the service principal with rights scoped to the registry.
# Default permissions are for docker pull access. Modify the '--role'
# argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles
SP_PASSWD=$(az ad sp create-for-rbac --name http://$ACR_PUSH_SERVICE_PRINCIPAL_NAME --scopes $ACR_REGISTRY_ID --role acrpull --query password --output tsv)
SP_APP_ID=$(az ad sp show --id http://$ACR_PUSH_SERVICE_PRINCIPAL_NAME --query appId --output tsv)

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
echo "Service principal ID: $SP_APP_ID"
echo "Service principal password: $SP_PASSWD"

# Add Open Service Broker for Azure
helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
helm install svc-cat/catalog --name catalog --namespace catalog --set apiserver.storage.etcd.persistence.enabled=true --set apiserver.healthcheck.enabled=false --set controllerManager.healthcheck.enabled=false --set apiserver.verbosity=2 --set controllerManager.verbosity=2 --wait
sleep 60
helm repo add azure https://kubernetescharts.blob.core.windows.net/azure
helm install azure/open-service-broker-azure --name osba --namespace osba --set azure.subscriptionId=$SUBSCRIPTION_ID --set azure.tenantId=$TENANT_ID --set azure.clientId=$SP_APP_ID --set azure.clientSecret=$SP_PASSWD --set modules.minStability=EXPERIMENTAL

# Create service instances
kubectl apply -f k8s-config/service-instance.yaml
sleep 600
# Restart DNS for lock up of new services
kubectl delete pods -l k8s-app=kube-dns -n kube-system

# Binding service instances
kubectl apply -f k8s-config/service-binding.yaml
