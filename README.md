# DoD-Inspired Secure Kubernetes Platform Lab

> A production-inspired GitOps platform built on Kubernetes, applying zero-trust security principles from DoD classified environments to cloud-native AWS infrastructure.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Security Controls](#security-controls)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup Guide](#setup-guide)
  - [1. AWS Account Setup](#1-aws-account-setup)
  - [2. Local Tooling](#2-local-tooling)
  - [3. SSH Key Generation](#3-ssh-key-generation)
  - [4. Terraform Infrastructure](#4-terraform-infrastructure)
  - [5. Kubernetes Bootstrap — Control Plane](#5-kubernetes-bootstrap--control-plane)
  - [6. Kubernetes Bootstrap — Worker Node](#6-kubernetes-bootstrap--worker-node)
  - [7. Deploy Podinfo](#7-deploy-podinfo)
  - [8. Install ArgoCD](#8-install-argocd)
- [Cost Management](#cost-management)
- [Why I Built This](#why-i-built-this)
- [What I Would Add In Production](#what-i-would-add-in-production)

---

## Overview

This lab replicates the platform engineering patterns used in DoD production environments, translated into cloud-native AWS infrastructure. The goal is to demonstrate how the same security rigor applied in classified, air-gapped systems — least privilege access, network segmentation, continuous compliance validation, and audit logging — can be implemented in a modern Kubernetes GitOps workflow.

Every architectural decision in this project is intentional and documented. This is not a tutorial copy-paste — it is a working security-focused platform built from first principles.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        GitHub                           │
│         devsecops-platform-lab (source of truth)        │
└─────────────────────┬───────────────────────────────────┘
                      │  GitOps sync (ArgoCD watches repo)
                      ▼
┌─────────────────────────────────────────────────────────┐
│                      AWS VPC (10.0.0.0/16)              │
│                                                         │
│  ┌──────────────────────┐  ┌──────────────────────┐    │
│  │   Control Plane      │  │    Worker Node        │    │
│  │   t3.small           │  │    t3.small           │    │
│  │   Rocky Linux 8      │  │    Rocky Linux 8      │    │
│  │   kubeadm            │  │    kubeadm join       │    │
│  │   ArgoCD             │  │    podinfo workload   │    │
│  └──────────────────────┘  └──────────────────────┘    │
│                                                         │
│  Security Group: least privilege ingress                │
│  CloudTrail: full audit logging                         │
│  IAM: least privilege node roles                        │
└─────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│              GitHub Actions Pipeline                    │
│  tfsec → Checkov → Trivy → Gitleaks                    │
└─────────────────────────────────────────────────────────┘
```

---

## Security Controls

| Control | Implementation | DoD Equivalent |
|--------|---------------|----------------|
| Access Control | Kubernetes RBAC — least privilege roles | DoD IAM / PAM controls |
| Network Segmentation | Default deny-all NetworkPolicy, explicit allow only | DISA STIG network segmentation |
| Container Scanning | Trivy — CVE detection on every push | ACAS / Nessus vulnerability scanning |
| IaC Scanning | Checkov + tfsec — misconfiguration detection | STIG compliance validation |
| Audit Logging | AWS CloudTrail — full API audit trail | SIEM / audit logging requirements |
| Secret Detection | Gitleaks — scans every commit for exposed secrets | Data Loss Prevention controls |
| SSH Hardening | Security group restricts SSH to management IP only | DISA STIG network access controls |
| OS Hardening | Rocky Linux 8 (RHEL-compatible), SELinux permissive | RHEL STIG baseline |
| CPU Credit Control | t3.small set to `standard` mode | Resource usage controls |

---

## Tech Stack

| Category | Tool |
|----------|------|
| Cloud | AWS (EC2, VPC, IAM, CloudTrail, S3) |
| IaC | Terraform |
| OS | Rocky Linux 8 (RHEL-compatible, free) |
| Container Runtime | containerd |
| Kubernetes | kubeadm v1.28 |
| Networking | Flannel CNI |
| GitOps | ArgoCD |
| Application | Podinfo |
| IaC Security | Checkov, tfsec |
| Container Security | Trivy |
| Secret Scanning | Gitleaks |
| CI/CD | GitHub Actions |

---

## Project Structure

```
devsecops-platform-lab/
├── terraform/
│   ├── main.tf                    # VPC, EC2, networking
│   ├── security.tf                # Security groups, CloudTrail, IAM
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # IP addresses, SSH commands
│   └── terraform.tfvars           # Your values (never commit this)
├── kubernetes/
│   └── apps/
│       └── podinfo/
│           ├── namespace.yaml
│           ├── deployment.yaml    # Non-root, read-only FS, resource limits
│           └── service.yaml
├── argocd/
│   └── application.yaml           # GitOps sync config
├── security/
│   ├── rbac/
│   │   └── roles.yaml             # Least privilege role bindings
│   └── network-policies/
│       └── deny-all.yaml          # Default deny, explicit allow
├── .github/
│   └── workflows/
│       └── security-pipeline.yaml # tfsec, Checkov, Trivy, Gitleaks
└── README.md
```

---

## Prerequisites

- AWS free tier account
- Git Bash (Windows) or terminal (Mac/Linux)
- Terraform installed
- AWS CLI installed and configured
- SSH key pair generated

---

## Setup Guide

### 1. AWS Account Setup

Create a free tier account at [aws.amazon.com](https://aws.amazon.com).

**Set a billing alarm immediately — non-negotiable:**
```
AWS Console → CloudWatch → Alarms → Billing → Create Alarm → $5 threshold
```

**Create an IAM user — never use root credentials:**
```
AWS Console → IAM → Users → Create User
Name: terraform-lab
Policy: AdministratorAccess (lab only — never do this in production)
```

Generate access keys for the IAM user and configure the AWS CLI:
```bash
aws configure
# Enter your Access Key ID, Secret Access Key, region (us-east-1), output format (json)
```

Verify your identity:
```bash
aws sts get-caller-identity
# Should show terraform-lab user, NOT root
```

---

### 2. Local Tooling

**Install Terraform:**
- Download from [developer.hashicorp.com/terraform/downloads](https://developer.hashicorp.com/terraform/downloads)
- Extract `terraform.exe` and place in `C:\Windows\System32\`

Verify:
```bash
terraform --version
```

**Install AWS CLI:**
- Download from [docs.aws.amazon.com/cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

---

### 3. SSH Key Generation

```bash
ssh-keygen -t rsa -b 4096
# Press enter through all prompts
```

Verify the key exists:
```bash
cat ~/.ssh/id_rsa.pub
```

---

### 4. Terraform Infrastructure

Clone the repo and navigate to the terraform directory:
```bash
git clone https://github.com/YOURUSERNAME/devsecops-platform-lab.git
cd devsecops-platform-lab/terraform
```

Create your `terraform.tfvars` file (never commit this):
```hcl
aws_region      = "us-east-1"
management_ip   = "YOUR_HOME_IP"   # find at whatismyip.com
public_key_path = "C:/Users/YOUR_USERNAME/.ssh/id_rsa.pub"
```

Initialize, plan, and apply:
```bash
terraform init
terraform plan    # Review what will be created — 13 resources
terraform apply   # Type 'yes' to confirm
```

Expected output:
```
Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:
control_plane_ip = "X.X.X.X"
worker_ip        = "X.X.X.X"
ssh_control_plane = "ssh -i ~/.ssh/id_rsa rocky@X.X.X.X"
ssh_worker        = "ssh -i ~/.ssh/id_rsa rocky@X.X.X.X"
```

**What gets created:**
- VPC with public subnet, internet gateway, and route table
- Two t3.small Rocky Linux 8 EC2 instances (control plane + worker)
- Security group with least privilege ingress — SSH and Kubernetes API restricted to your IP only
- IAM role with SSM access only — no broad API permissions
- CloudTrail logging all API calls to an S3 bucket

---

### 5. Kubernetes Bootstrap — Control Plane

SSH into the control plane:
```bash
ssh -i ~/.ssh/id_rsa rocky@CONTROL_PLANE_IP
```

Run all setup commands:
```bash
# Disable swap — required for Kubernetes
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Set kernel networking parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# Install containerd from Docker repo (not in Rocky 8 default repos)
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable --now containerd

# Add Kubernetes repo and install
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF
sudo dnf install -y kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# Set SELinux to permissive — required for kubeadm
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

Initialize the cluster:
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

Configure kubectl:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Install Flannel CNI networking:
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

Verify control plane is ready:
```bash
kubectl get nodes
# NAME                         STATUS   ROLES           AGE   VERSION
# ip-10-0-1-x.ec2.internal     Ready    control-plane   2m    v1.28.15
```

**Save the join command from the kubeadm init output** — you will need it for the worker node:
```
kubeadm join 10.0.1.X:6443 --token XXXXX --discovery-token-ca-cert-hash sha256:XXXXX
```

---

### 6. Kubernetes Bootstrap — Worker Node

Open a second terminal and SSH into the worker node:
```bash
ssh -i ~/.ssh/id_rsa rocky@WORKER_IP
```

Run the same setup commands as the control plane (all steps up to but not including `kubeadm init`), then join the cluster using sudo:
```bash
sudo kubeadm join 10.0.1.X:6443 --token XXXXX \
        --discovery-token-ca-cert-hash sha256:XXXXX
```

Back on the control plane, verify both nodes are ready:
```bash
kubectl get nodes
# NAME                         STATUS   ROLES           AGE   VERSION
# ip-10-0-1-x.ec2.internal     Ready    control-plane   5m    v1.28.15
# ip-10-0-1-x.ec2.internal     Ready    <none>          1m    v1.28.15
```

---

### 7. Deploy Podinfo

```bash
kubectl create namespace podinfo
kubectl apply -f https://raw.githubusercontent.com/stefanprodan/podinfo/master/kustomize/deployment.yaml -n podinfo
kubectl apply -f https://raw.githubusercontent.com/stefanprodan/podinfo/master/kustomize/service.yaml -n podinfo
```

Verify:
```bash
kubectl get pods -n podinfo
# NAME                       READY   STATUS    RESTARTS   AGE
# podinfo-7cb48446b6-xxxxx   1/1     Running   0          15s
```

---

### 8. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Watch pods come up:
```bash
kubectl get pods -n argocd --watch
# Wait until all pods show Running, then Ctrl+C
```

---

## Cost Management

This lab is designed to cost as little as possible. Two t3.small instances cost approximately $0.04/hour combined.

**Always destroy when not actively working:**
```bash
cd terraform/
terraform destroy
```

**Always rebuild when resuming:**
```bash
terraform apply
```

Since all infrastructure is defined as code, rebuilding takes under 5 minutes. Your cluster state will not persist between sessions — redeploy workloads after each rebuild using the kubectl commands above.

**Set a $5 billing alarm in AWS CloudWatch.** This is non-negotiable.

Estimated monthly cost with daily 4-hour sessions: under $5.

---

## Why I Built This

My current role as a Cybersecurity Engineer at the Department of Defense involves working in classified, air-gapped environments — systems that cannot connect to commercial cloud services. While this gives me deep experience with security rigor, compliance automation, and infrastructure hardening, it means I cannot demonstrate that work publicly.

This project replicates the same principles I apply daily in classified environments, translated into cloud-native infrastructure:

- The RBAC roles mirror the need-to-know access controls I enforce on DoD systems
- The default deny NetworkPolicies mirror the network segmentation I configure on classified networks
- The Trivy and Checkov scanning mirrors the Nessus and STIG validation I automate with Ansible and PowerShell
- The CloudTrail audit logging mirrors the SIEM and audit logging requirements I maintain for continuous monitoring
- The GitOps workflow mirrors the CI/CD security pipelines I built using GitLab in production

The OS choice — Rocky Linux 8 — is intentional. It is binary-compatible with RHEL 8, which is the operating system I administer daily. Every `dnf` command, every SELinux configuration, and every systemd service in this lab is directly transferable to production RHEL environments.

---

## What I Would Add In Production

- **Secrets management** — HashiCorp Vault or AWS Secrets Manager instead of Kubernetes secrets
- **Service mesh** — Istio for mTLS between services, replacing implicit trust with verified encryption
- **Policy enforcement** — OPA Gatekeeper to enforce security policies at admission time
- **Runtime threat detection** — Falco for detecting anomalous container behavior
- **Image signing** — Cosign to verify container image provenance before deployment
- **Multi-environment GitOps** — Separate ArgoCD ApplicationSets for dev, staging, and production
- **Cluster hardening** — CIS Kubernetes Benchmark compliance via kube-bench
- **Centralized logging** — Loki or OpenSearch for aggregated log analysis across nodes

## Known Findings and Accepted Risk

This lab intentionally accepts certain findings due to free tier constraints.
In a production environment every one of these would be remediated.

| Finding | Why Accepted in Lab | Production Remediation |
|---------|-------------------|----------------------|
| EBS not optimized (CKV_AWS_135) | t3.small does not support EBS optimization | Use t3.large or larger |
| Public subnet IP assignment (CKV_AWS_130) | Required for SSH access without NAT Gateway | Add NAT Gateway, use private subnets |
| Unrestricted egress (CKV_AWS_382) | Required for package installation | Restrict to known endpoints |
| CloudTrail not multi-region (CKV_AWS_67) | Single region lab only | Set is_multi_region_trail = true |
| CloudTrail no KMS encryption (CKV_AWS_35) | KMS costs money | Create CMK and attach to CloudTrail |
| CloudTrail no SNS topic (CKV_AWS_252) | Not needed for lab | Add SNS for real-time alerts |
| CloudTrail no CloudWatch (CKV2_AWS_10) | Added complexity beyond scope | Integrate with CloudWatch Logs |
| S3 no KMS encryption (CKV_AWS_145) | KMS costs money | Create CMK for S3 bucket |
| S3 no cross-region replication (CKV_AWS_144) | Costs money | Enable replication to DR region |
| S3 no access logging (CKV_AWS_18) | Lab environment | Enable S3 server access logging |
| S3 no lifecycle policy (CKV2_AWS_61) | Lab — bucket destroyed regularly | Add lifecycle rule to expire logs |
| S3 no event notifications (CKV2_AWS_62) | Not needed for lab | Add SNS/SQS notifications |
| VPC no flow logs (CKV2_AWS_11) | Added cost and complexity | Enable VPC flow logs to S3 |
| Default VPC SG not restricted (CKV2_AWS_12) | Lab environment | Explicitly restrict default SG |
| No NetworkPolicy associated (CKV2_K8S_6) | False positive — NetworkPolicy exists in security/network-policies/deny-all.yaml | No action needed |
| Upstream image CVEs (Trivy) | 14 CVEs in podinfo base image including OpenSSL and Go stdlib vulnerabilities. All are upstream dependencies outside our control. Fixed versions exist but require upstream image rebuild by maintainer. | Pin to updated image digest when maintainer releases patched version. Tracked via automated Trivy scan on every commit. |