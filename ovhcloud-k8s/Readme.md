## Getting Coder Installed

1. Create an OVH Cloud account, order a public cloud, and then set up a project (copy the ID)
2. Fork this repo and set it up with [spacelift.io](https://spacelift.io/) or equivalent
3. Set OVH_CLOUD_PROJECT_SERVICE to the project id from (1)
4. For US, I went to https://api.us.ovhcloud.com/createToken/?GET=/*&POST=/*&PUT=/*&DELETE=/* to generate API keys
5. Set OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY to the values from (4)
6. Make sure to set the root directory to ovhcloud-k8s/
4. Run and apply the Terraform (took me 10 minutes)

## Coder setup Instructions

1. In the OVHCloud Console, go to Public Cloud --> Load Balancer and copy the IP address on the far right.
2. Create the initial username and password.
3. Go to Templates, click Develop in Kubernetes, and click use template
4. Click create template (it will refresh and prompt for 3 more template inputs)
5. Set var.use_kubeconfig to false 
6. Set var.namespace to coder
7. Click create template

With the admin user created and the template imported, we are ready to launch a workspace based on that template.

1. Click create workspace from the kubernetes template (templates/kubernetes/workspace)
2. Give it a name and click create
3. Within three minutes, the workspace should launch.

From there, you can click the Terminal button to get an interactive session in the k8s container, or you can click code-server to open up a VSCode window and start coding!

## In Terraform, k8s and helm providers: dial tcp 127.0.0.1:80: connect: connection refused

There is a chicken-and-egg problem when it comes to authenticating with your k8s cluster. Before the cluster is deployed, since there are no resources, the k8s provider has nothing to check. Terraform creates the cluster, generates kubeconfig, and the k8s provider happily does its job. However, once these resources are created, Terraform's plan phase will activate the k8s provider which will need the kubeconfig, which will only happy during apply time.

This issue happens for other cloud providers, but they all have workarounds. A Terraform data source object works as it's activated during plan, and for AKS, the k8s provider allows you to shell out to the command line.

The workaround for OVHCloud is to mount the kubeconfig file directly in, which is easy using Spacelift:

1. Go to OVHCloud --> Kubernetes --> Service, and in the Access and security panel you can download the kubeconfig file.
2. Go to your Spacelift stack --> Environment, and click Edit.
3. Change the type to "Mounted File", and upload the kubeconfig file from (1)
4. Set the path to "/mnt/workspace/source/ovhcloud-k8s/config.yml"
