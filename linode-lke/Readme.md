## Getting Coder Installed

1. Fork this repo and set it up with [spacelift.io](https://spacelift.io/) or equivalent
2. Set LINODE_TOKEN to your [Linode API Key](https://cloud.linode.com/profile/tokens)
3. Make sure to set the root directory to linode-lke/
4. Run and apply the Terraform (took me 8 minutes)

## Coder setup Instructions

1. Go to [Node Balancers](https://cloud.linode.com/nodebalancers) and copy the public IP address
2. Go to Services and the public IP should be on the right.
3. Create the initial username and password.
4. Go to Templates, click Develop in Kubernetes, and click use template
5. Click create template (it will refresh and prompt for 3 more template inputs)
6. Set var.use_kubeconfig to false 
7. Set var.namespace to coder
8. Click create template

With the admin user created and the template imported, we are ready to launch a workspace based on that template.

1. Click create workspace from the kubernetes template (templates/kubernetes/workspace)
2. Give it a name and click create
3. Within three minutes, the workspace should launch.

From there, you can click the Terminal button to get an interactive session in the k8s container, or you can click code-server to open up a VSCode window and start coding!
