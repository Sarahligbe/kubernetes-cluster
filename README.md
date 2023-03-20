# Deploying a Kubernetes cluster with Terraform, a CI/CD pipeline with Github actions and ArgoCD, and monitoring set up.

To replicate this locally, clone the repo and do the following:
1. Set your AWS credentials as environment variables
2. Make sure you already have a route53 hosted zone, add your domain name in the terraform.tfvars file
3. Set the following terraform environment variables:
- The slack api url for argocd to send build information
```bash
export TF_VAR_argoslack=""
```
- The slack api url for alert manager to send alerts
```bash
export TF_VAR_prometheusslack=""
```
- The ArgoCD login password to view the deployments. The password has to be bcrypt hashed
```bash
export $PASS=""
export TF_VAR_argopass=$(htpasswd -nbBC 10 "" $PASS | tr -d ':\n' | sed 's/$2y/$2a/')
```
You can also set these variables in Github Actions secrets.

My sock-shop is hosted on [sock.sarahligbe.live](https://sock.sarahligbe.live)  
My portfolio is hosted on [portfolio.sarahligbe.live](https://portfolio.sarahligbe.live)  
ArgoCD is hosted on [argocd.sarahligbe.live](https://argocd.sarahligbe.live)  (**username = admin**)
Grafana is hosted on [graf.sarahligbe.live](https://graf.sarahligbe.live)  (**username = admin**)
Prometheus is hosted on [prom.sarahligbe.live](https://prom.sarahligbe.live)

For this project, I set up:
- A VPC with public, private and intra subnets. The intra subnets were to be assigned to the Control plane, while the Worker nodes were in the private subnet.
- Karpenter for autoscaling
- Cert manager and Let's Encrypt for SSL
- Nginx ingress to route traffic from the pods to the internet
- Prometheus and Grafana for monitoring
- AWS Cloudwatch for logging
- Github Actions for CI
- ArgoCD for continuous deployment of the applications in the kubernetes cluster.  

The ArgoCD deployment:
![Argocd deployments](images/argo-cd.jpg)  

The ArgoCD slack alert:
![ArgoCD slack](images/argocdbuild.jpg)  

The sock-shop website: 
![sockshop](images/sock.jpg)  

The portfolio website:
![portfolio](images/portfolio.jpg)  

Prometheus:
![prometheus](images/prom.jpg)    
![prometheus](images/prom2.jpg)  

Grafana dashboard:
![grafana](images/graf.jpg)  

Let's Encrypt certificate (got a wildcard certificate to cover all the subdomains)  
![cert](images/cert.jpg)

Github actions workflow:
![git_actions](images/git_actions.jpg)
