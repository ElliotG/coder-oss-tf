## Getting Coder Installed

1. Fork this repo and set it up with [spacelift.io](https://spacelift.io/) or equivalent
2. Create a [Scaleway API Key](https://console.scaleway.com/iam/api-keys) and set both SCW_ACCESS_KEY and SCW_SECRET_KEY
3. Set SCW_DEFAULT_PROJECT_ID to your [project ID](https://console.scaleway.com/project/settings)
3. Make sure to set the root directory to scaleway-kapsule/
4. Run and apply the Terraform (took me 8 minutes)

## Coder setup Instructions

1. Navigate to your cluster dashboard (Kubernetes / coder / Dashboard)
2. Change the namespace to coder (upper left)
3. Go to Services and the public IP should be on the right.
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
