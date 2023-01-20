## Getting Coder Installed

1. Create an OVH Cloud account, order a public cloud, and then set up a project (copy the ID)
2. Fork this repo and set it up with [spacelift.io](https://spacelift.io/) or equivalent
3. Set OVH_CLOUD_PROJECT_SERVICE to the project id from (1)
4. For US, I went to https://api.us.ovhcloud.com/createToken/?GET=/*&POST=/*&PUT=/*&DELETE=/* to generate API keys
5. Set OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY to the values from (4)
6. Make sure to set the root directory to ovhcloud-k8s/
7. Run and apply the Terraform (took me 10 minutes)

If you run into any auth issues, see the end of the Readme.

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