## Getting Coder Installed

1. Create an [AWS Account](https://portal.aws.amazon.com/billing/signup#/start/email).
2. Create an IAM User with the Administrator policy. Generate access keys and grant it console access. See bottom for notes.
2. Fork this repo and set it up with [spacelift.io](https://spacelift.io/) or equivalent.
3. Set [AWS_ACCESS_KEY_ID](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) and [AWS_SECRET_ACCESS_KEY](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
4. Make sure to set the directory to eks
4. Run and apply the Terraform (takes 15 minutes).

## Coder setup Instructions

To get Coder set up initially, we need to give it an admin user and create a kubernetes template for our workspace.

1. Navigate to the DNS of the load balancer (AWS / EC2 / Load balancers).
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

## Why grant the Terraform user Console Access?
Most of the kubernetes resources can only be managed if granted permissions via the kubernetes cluster role binding. The (AWS docs)[https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html] can step you through how to do this. It cannot be granted via IAM alone, except for the IAM user that originally created the EKS cluster. For this reason, it's easiest to grant the Terraform user console access so you can view the properties of the cluster. In production, you'd want to do this differently.

## Why did I fork coder's helm chart?
Due to a limitation in AWS, I needed to make a [change](https://github.com/coder/coder/pull/5448) to the Helm chart. Until this is fully released, I've forked the helm chart locally.

## The VPC creation failed
There's a rare AWS bug that can cause the VPC to fail to be created, but still create anyway. Sucks. Gotta delete and try again.

## The Postgres pod is failing to get it's Persistent Volume created
If you've tried to apply multiple times, there could be a duplicate volume. There's a wierd bug the way Terraform destroys the Helm chart that can leave the Persistent Volume around. Check to see if the volume already exists and manually delete it.

## Authentication to Kubernetes is failing
I've found AWS to be a bit unstable with it's auth. I had to use different auth techniques depending on if I was using Spacelift vs Terraform Cloud. I've documented both techniques in main.tf in the comments.
