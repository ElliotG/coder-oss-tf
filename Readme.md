# Coder OSS on GKE with Terraform in <20 minutes

The purpose of this repo is to demonstrate how remote development environments work using Coder's OSS product. This repo should not be used for production use cases, but simply a proof-of-concept for what coding-in-a-browser feels like using Coder.

<img src="images/vscode.png" width="300">

## Getting Coder Installed (10 minutes)

1. Create a [Google Cloud Account](https://cloud.google.com/), [a project](https://console.cloud.google.com/projectcreate), and [a service account](https://console.cloud.google.com/iam-admin/serviceaccounts/create) in that project with [editor](https://cloud.google.com/iam/docs/understanding-roles#basic) permissions.
2. Fork this repo and set it up with [spacelift.io](https://spacelift.io/) or equivalent
3. Set [GOOGLE_CREDENTIALS](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#using-terraform-cloud) and TF_VAR_project with the project id from above
4. Run and apply the Terraform.

The entire setup should take you less than 30 minutes, though if you are new to Google Cloud or Spacelift, it might take you a little bit longer. 

## Coder setup Instructions (5 minutes)

1. Navigate to the IP address of the load balancer (Google Cloud / Kubernetes Engine / Services & Ingress.
2. Create the initial username and password.
3. Go to Templates / Kubernetes / Create Workspace and give the workspace a name.
4. Within three minutes, the workspace should launch.
5. Click the code-server button, and start coding.
