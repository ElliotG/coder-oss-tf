# Coder OSS on GKE with Terraform and Spacelift in <20 minutes

From Repo

<img src="images/repo.png" width="300">

To fully remote VS code in <20 minutes. Let's go!

<img src="images/vscode.png" width="300">

The purpose of this repo is to get you exploring how Coder works in the quickest time possible. This repo assumes you have full access to the underlying account / project, and it is a very good fit for using your personal email address. The idea is for you to check out what a fully remote dev environment looks/feels like, before committing to a deeper investigation.

## Getting Coder Installed

1. Create a [Google Cloud Account](https://cloud.google.com/), [a project](https://console.cloud.google.com/projectcreate), and [a service account](https://console.cloud.google.com/iam-admin/serviceaccounts/create) in that project with [editor](https://cloud.google.com/iam/docs/understanding-roles#basic) permissions.
2. Fork this repo and set it up with [spacelift.io](https://spacelift.io/) or equivalent
3. Set [GOOGLE_CREDENTIALS](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#using-terraform-cloud) and TF_VAR_project with the project id from above
4. Run and apply the Terraform.
5. Head to the Google Cloud Console / Kubernetes Engine / Service & Ingress
6. Copy the URL from the Coder external load balancer (http://<ip_address>)
7. Go back to Spacelift and set TF_VAR_coder_access_url to this URL

The entire setup should take you less than 30 minutes, though if you are new to Google Cloud or Spacelift, it might take you a little bit longer. 

## Coder setup Instructions:

1. Navigate to the IP address of the load balancer (Google Cloud / Kubernetes Engine / Services & Ingress.
2. Create the initial username and password.
3. Go to Templates / Kubernetes / Create Workspace and give the workspace a name.
4. Within three minutes, the workspace should launch.
5. Click the code-server button, and start coding.
