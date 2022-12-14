## Getting Coder Installed

1. Create an [AWS Account](https://portal.aws.amazon.com/billing/signup#/start/email).
2. Create an IAM User with the Administrator policy. Generate access keys and grant it console access. See bottom for notes.
2. Fork this repo and set it up with [spacelift.io](https://spacelift.io/) or equivalent.
3. Set [AWS_ACCESS_KEY_ID](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) and [AWS_SECRET_ACCESS_KEY](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

3. Set [GOOGLE_CREDENTIALS](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#using-terraform-cloud) and TF_VAR_project with the project id from above
4. Make sure to set the directory to gke
4. Run and apply the Terraform (takes 10 minutes).

## Coder setup Instructions

1. Navigate to the IP address of the load balancer (Google Cloud / Kubernetes Engine / Services & Ingress.
2. Create the initial username and password.
3. Go to Templates / Kubernetes / Create Workspace and give the workspace a name.
4. Within three minutes, the workspace should launch.
5. Click the code-server button, and start coding.



## Why grant the Terraform user Console Access?
Most of the kubernetes resources can only be managed if granted permissions via the kubernetes cluster role binding. The (AWS docs)[https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html] can step you through how to do this. It cannot be granted via IAM alone, except for the IAM user that originally created the EKS cluster. For this reason, it's easiest to grant the Terraform user console access so you can view the properties of the cluster. In production, you'd want to do this differently.