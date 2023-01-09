## Getting Coder Installed

1. Fork this repo and set it up with [spacelift.io](https://spacelift.io/) or equivalent
2. Create an [API Key](https://cloud.ibm.com/docs/account?topic=account-userapikey&interface=ui) and set it as IC_API_KEY
3. Make sure to set the root directory to ibmcloud-k8s/
4. Run and apply the Terraform (took me 10 minutes)

## Coder setup Instructions

1. In the IBMCloud Console, go to Kubernetes --> coder --> Kubernetes Dashboard (upper right)
2. Change the namespace to coder (upper left)
3. Go to Servicesm, and the public IP should be on the right.
4. Create the initial username and password.
5. Go to Templates, click Develop in Kubernetes, and click use template
6. Click create template (it will refresh and prompt for 3 more template inputs)
7. Set var.use_kubeconfig to false 
8. Set var.namespace to coder
9. Click create template

With the admin user created and the template imported, we are ready to launch a workspace based on that template.

1. Click create workspace from the kubernetes template (templates/kubernetes/workspace)
2. Give it a name and click create
3. Within three minutes, the workspace should launch.

From there, you can click the Terminal button to get an interactive session in the k8s container, or you can click code-server to open up a VSCode window and start coding!

## In Terraform: dial tcp 127.0.0.1:80: connect: connection refused

This is a Terraform bug that is really obnoxious. The only way to fix it is to manually delete things in the console/state until you get back to a good state. Or you need to fork my repo.

Terraform does an "optimization" where it will skip calculating a data resource if it depends on an object that needs to be recreated. For this repo, that data resource is the one that uses your IBMCloud credentials to pull k8s config for deploying the helm charts. If you modify the k8s cluster, Terraform can skip trying to calculate the datasource. When the provider tries to run, it doesn't find the config file, and defaults to 127.0.0.1. 

There are many Github issues filed on this topic, and they all come down to the same solution: install ibmcloud's cli and plugin in your CI system, and farming out to the command line to generate kubectl. Unfortunately, IBM Cloud's CLI is not installed by default on most Terraform CI systems, so you'd have to run on a custom docker image and the rabbit hole grows. 

## Workspace launches but code-server/VSCode doesn't work?

IBM does weird stuff with it's volumes. Use the terminal to chown ~, and it should work.
