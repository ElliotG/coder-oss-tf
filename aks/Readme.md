## Getting Coder Installed

1. Create an [Azure Account](https://portal.azure.com/) and [a service principal](https://docs.spacelift.io/integrations/cloud-providers/azure#create-a-service-principal).
2. Fork this repo and set it up with [spacelift.io](https://spacelift.io/) or equivalent
3. Set ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID using the values when you created the service principal.
4. Make sure to set the directory to aks
4. Run and apply the Terraform (takes 10 minutes).

## Coder setup Instructions

1. Navigate to the IP address of the load balancer (Kubernetes services / coder-k8s-cluster / Services & Ingresses.
2. Create the initial username and password.
3. Go to Templates / Kubernetes / Create Workspace and give the workspace a name.
4. Within three minutes, the workspace should launch.
5. Click the code-server button, and start coding.
