# EKS Cluster Connection Guide

This guide will help you connect to your EKS cluster and verify it's functional.

## Prerequisites

Before connecting to the cluster, ensure you have the following tools installed:

1. **AWS CLI** (v2.x or later)
   ```bash
   aws --version
   ```

2. **kubectl** (Kubernetes command-line tool)
   ```bash
   # Install kubectl on macOS
   brew install kubectl
   
   # Verify installation
   kubectl version --client
   ```

3. **AWS Credentials** configured
   ```bash
   aws sts get-caller-identity
   ```

## Step 1: Get Cluster Information

First, verify the cluster was created successfully:

```bash
# From the project root
cd /Users/savak/Projects/BoardGameShop/bg-tf-app

# Get outputs from the compute environment
make output-eks

# Alternative: Get directly from Terraform
cd live/dev/eu-west-1/compute
terraform output
```

You should see outputs including:
- `cluster_endpoint`
- `cluster_arn`
- `configure_kubectl` (the command to configure kubectl)

## Step 2: Configure kubectl

Use the AWS CLI to configure kubectl to connect to your cluster:

```bash
# Using the output from Terraform
aws eks update-kubeconfig --region eu-west-1 --name bg-eks-dev

# This command will:
# - Add cluster configuration to ~/.kube/config
# - Set the current context to your EKS cluster
```

**Expected output:**
```
Added new context arn:aws:eks:eu-west-1:ACCOUNT_ID:cluster/bg-eks-dev to /Users/savak/.kube/config
```

## Step 3: Verify Cluster Connection

### Check kubectl context
```bash
# Verify current context
kubectl config current-context

# Should show something like:
# arn:aws:eks:eu-west-1:ACCOUNT_ID:cluster/bg-eks-dev
```

### Check cluster info
```bash
# Get cluster information
kubectl cluster-info

# Expected output:
# Kubernetes control plane is running at https://YOUR_CLUSTER_ENDPOINT
# CoreDNS is running at https://YOUR_CLUSTER_ENDPOINT/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

## Step 4: Verify Nodes

Check that your worker nodes are ready:

```bash
# List all nodes
kubectl get nodes

# Expected output (should show 3 nodes):
# NAME                                         STATUS   ROLES    AGE   VERSION
# ip-10-10-0-XX.eu-west-1.compute.internal     Ready    <none>   Xm    v1.31.x
# ip-10-10-1-XX.eu-west-1.compute.internal     Ready    <none>   Xm    v1.31.x
# ip-10-10-0-XX.eu-west-1.compute.internal     Ready    <none>   Xm    v1.31.x
```

### Get detailed node information
```bash
# Get nodes with more details
kubectl get nodes -o wide

# Describe a specific node
kubectl describe node <node-name>
```

## Step 5: Check System Pods

Verify that system components are running:

```bash
# Check all pods in kube-system namespace
kubectl get pods -n kube-system

# Expected pods:
# - coredns-* (DNS)
# - aws-node-* (VPC CNI)
# - kube-proxy-* (Network proxy)
```

### Check pod status in detail
```bash
# Get all system pods with status
kubectl get pods -n kube-system -o wide

# Check if all pods are Running
kubectl get pods -n kube-system | grep -v Running
```

## Step 6: Deploy a Test Application

Deploy a simple nginx application to verify the cluster is functional:

```bash
# Create a test namespace
kubectl create namespace test-app

# Deploy nginx
kubectl create deployment nginx --image=nginx:latest -n test-app

# Verify deployment
kubectl get deployments -n test-app

# Check pods
kubectl get pods -n test-app

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=nginx -n test-app --timeout=60s
```

### Expose the application

**Option A: LoadBalancer (creates an AWS ELB)**
```bash
# Create a service (LoadBalancer type will create an AWS ELB)
kubectl expose deployment nginx --port=80 --type=LoadBalancer -n test-app

# Get service details
kubectl get svc -n test-app

# Wait for the LoadBalancer to be provisioned (EXTERNAL-IP will show)
kubectl get svc nginx -n test-app -w
```

**Option B: NodePort (external access via node's port - requires security group configuration)**
```bash
# Expose the deployment as a NodePort service
kubectl expose deployment nginx --port=80 --type=NodePort -n test-app

# Get the NodePort value
kubectl get svc nginx -n test-app -o jsonpath='{.spec.ports[0].nodePort}'
# Example output: 31234

# Get a node IP
kubectl get nodes -o wide

# Access the app using <NODE_IP>:<NODE_PORT>
# Example:
curl http://<NODE_IP>:31234
```
> **Important:** NodePort opens a port in the 30000–32767 range on each node, but **by default, EKS node security groups block external access to these ports**. You will likely get a timeout error.
> 
> To make NodePort work, you need to:
> 1. Find your EKS node security group in the AWS Console (EC2 → Security Groups)
> 2. Add an inbound rule: Custom TCP, Port range: 30000-32767, Source: Your IP address
> 
> **Alternative:** If you don't want to modify security groups, use **Option C (port-forward)** instead, which bypasses security groups entirely by tunneling through the Kubernetes API.

**Option C: kubectl port-forward (recommended for local testing)**
```bash
# Create a ClusterIP service (default type, internal only)
kubectl expose deployment nginx --port=80 -n test-app

# Port-forward the service to localhost (service is preferred as it handles pod restarts)
kubectl port-forward svc/nginx 8080:80 -n test-app

# Or port-forward a specific pod
# Get the nginx pod name first
kubectl get pods -n test-app -l app=nginx
kubectl port-forward pod/<nginx-pod-name> 8080:80 -n test-app

# In another terminal, test locally
curl http://localhost:8080
```
> **Note:** `kubectl port-forward` is local-only and secure for quick testing. It runs until you press Ctrl+C. No external load balancer or security group changes required.

### Test the application (for LoadBalancer option)
```bash
# Get the LoadBalancer URL
export LB_URL=$(kubectl get svc nginx -n test-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Wait a moment for DNS propagation, then test
curl http://$LB_URL

# Should return nginx welcome page HTML
```

## Step 7: Check Cluster Health

### Check component status
```bash
# Check cluster components
kubectl get componentstatuses

# Check cluster API server
kubectl get --raw='/readyz?verbose'

# Check node conditions
kubectl get nodes -o json | jq '.items[].status.conditions[] | select(.type=="Ready")'
```

### View cluster events
```bash
# See recent cluster events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events -n kube-system -w
```

## Step 8: Verify OIDC Provider (IRSA)

Check that IRSA (IAM Roles for Service Accounts) is configured:

```bash
# Get OIDC provider URL from Terraform output
cd /Users/savak/Projects/BoardGameShop/bg-tf-app/live/dev/eu-west-1/compute
terraform output oidc_provider_url

# Verify OIDC provider in AWS
aws iam list-open-id-connect-providers

# You should see your cluster's OIDC provider listed
```

## Step 9: Check Cluster Logs (Optional)

View EKS control plane logs (if enabled):

```bash
# Control plane logs are sent to CloudWatch
# View available log streams
aws logs describe-log-groups --log-group-name-prefix /aws/eks/bg-eks-dev

# View recent API server logs
aws logs tail /aws/eks/bg-eks-dev/cluster --follow
```

## Step 10: Cleanup Test Resources

After verifying everything works, clean up the test application:

```bash
# Delete the test application
kubectl delete namespace test-app

# This will remove:
# - The nginx deployment
# - The LoadBalancer service (and AWS ELB)
# - All resources in the test-app namespace
```

## Troubleshooting

### Issue: "error: You must be logged in to the server (Unauthorized)"

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Reconfigure kubectl
aws eks update-kubeconfig --region eu-west-1 --name bg-eks-dev
```

### Issue: "No resources found" when checking nodes

**Possible causes:**
1. Node group is still being created (wait 5-10 minutes)
2. Check node group status:
   ```bash
   aws eks describe-nodegroup --cluster-name bg-eks-dev --nodegroup-name bg-eks-dev-node-group --region eu-west-1
   ```

### Issue: Pods stuck in "Pending" state

**Check:**
```bash
# Describe the pod to see events
kubectl describe pod <pod-name> -n <namespace>

# Check node capacity
kubectl describe nodes

# Check if nodes have enough resources
kubectl top nodes
```

### Issue: Cannot access LoadBalancer service

**Check:**
1. Security groups allow inbound traffic on port 80
2. LoadBalancer is fully provisioned:
   ```bash
   kubectl describe svc nginx -n test-app
   ```
3. AWS ELB is healthy:
   ```bash
   aws elb describe-load-balancers --region eu-west-1
   ```

## Useful Commands

### Quick health check script
```bash
#!/bin/bash
echo "=== Cluster Info ==="
kubectl cluster-info

echo -e "\n=== Nodes ==="
kubectl get nodes

echo -e "\n=== System Pods ==="
kubectl get pods -n kube-system

echo -e "\n=== All Namespaces ==="
kubectl get namespaces

echo -e "\n=== Recent Events ==="
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20
```

### Monitor cluster resources
```bash
# Install metrics-server (optional, for kubectl top)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View node resource usage
kubectl top nodes

# View pod resource usage
kubectl top pods --all-namespaces
```

## Next Steps

Once you've verified the cluster is functional:

1. **Set up ingress controller** (e.g., AWS Load Balancer Controller, NGINX Ingress)
2. **Configure IRSA** for your applications
3. **Install monitoring** (Prometheus, Grafana)
4. **Set up logging** (Fluentd, CloudWatch)
5. **Configure autoscaling** (Cluster Autoscaler or Karpenter)
6. **Deploy your applications**

## Additional Resources

- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)

## Getting Help

If you encounter issues:

1. Check Terraform state: `cd live/dev/eu-west-1/compute && terraform show`
2. Review AWS Console: EKS → Clusters → bg-eks-dev
3. Check CloudWatch logs for control plane issues
4. Review security group rules in VPC console
