## Getting Coder Installed

1. Create a [Google Cloud Account](https://cloud.google.com/), [a project](https://console.cloud.google.com/projectcreate), and [a service account](https://console.cloud.google.com/iam-admin/serviceaccounts/create) in that project with [editor](https://cloud.google.com/iam/docs/understanding-roles#basic) permissions.
2. Fork this repo and set it up with [spacelift.io](https://spacelift.io/) or equivalent
3. Set [GOOGLE_CREDENTIALS](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#using-terraform-cloud) and TF_VAR_project with the project id from above
4. Make sure to set the directory to gke
4. Run and apply the Terraform (takes 10 minutes).

## Coder setup Instructions

1. Navigate to the IP address of the load balancer (Google Cloud / Kubernetes Engine / Services & Ingress.
2. Create the initial username and password.
3. Go to Templates, click Develop in Kubernetes, and click use template
4. Click create template (it will refresh and prompt for 3 more template inputs)
5. Set var.use_kubeconfig to false 
6. Set var.namespace to coder
6. Click create template

With the admin user created and the template imported, we are ready to launch a workspace based on that template.

1. Click create workspace from the kubernetes template (templates/kubernetes/workspace)
2. Give it a name and click create
3. Within three minutes, the workspace should launch.

From there, you can click the Terminal button to get an interactive session in the k8s container, or you can click code-server to open up a VSCode window and start coding!