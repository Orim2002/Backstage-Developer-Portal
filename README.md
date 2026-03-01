# Self-Service Developer Portal

A production-grade internal developer portal built with [Spotify Backstage](https://backstage.io), deployed on AWS using Terraform and ECS Fargate. Enables developers to create microservices with a GitHub repository, CI/CD pipeline, and catalog registration at the click of a button.

---

## Features

- **Software Catalog** — Registry of all services, APIs, and teams
- **Self-Service Templates** — Create microservices with repo + CI/CD in one click
- **GitHub Integration** — CI/CD pipeline visibility, repo linking
- **GitHub OAuth** — Secure authentication via GitHub
- **Production-Ready AWS Infrastructure** — ECS Fargate, RDS PostgreSQL, ALB, VPC

---

## Architecture

```
Internet
    ↓
ALB (public subnet)
    ↓
ECS Fargate — Backstage (private subnet)
    ↓
RDS PostgreSQL (private subnet)
```

### AWS Infrastructure

```
VPC (us-east-1)
├── Public Subnets (3 AZs)
│   ├── Application Load Balancer
│   └── NAT Gateways
├── Private Subnets — App (3 AZs)
│   └── ECS Fargate (Backstage)
└── Private Subnets — Data (3 AZs)
    └── RDS PostgreSQL 15
```

### Terraform Modules

```
infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
└── modules/
    ├── vpc/     — VPC, subnets, NAT gateways, route tables
    ├── alb/     — Application Load Balancer, target groups, listener rules
    ├── rds/     — PostgreSQL RDS instance, subnet group, security groups
    └── ecs/     — ECS cluster, Fargate service, task definition, ECR, IAM
```

---

## Prerequisites

- Node.js 20+ (via nvm recommended)
- Yarn
- Docker
- Terraform >= 1.5
- AWS CLI configured
- GitHub account

---

## Local Development

### 1. Clone the repository

```bash
git clone https://github.com/Orim2002/developer-portal
cd developer-portal
```

### 2. Install dependencies

```bash
nvm use 20
yarn install
```

### 3. Set environment variables

```bash
export GITHUB_TOKEN=ghp_your_token_here
export AUTH_GITHUB_CLIENT_ID=your_client_id
export AUTH_GITHUB_CLIENT_SECRET=your_client_secret
export NODE_OPTIONS=--no-node-snapshot
```

#### Creating a GitHub Personal Access Token

Go to GitHub → Settings → Developer Settings → Personal Access Tokens → Generate new token

Required scopes: `repo`, `workflow`, `read:org`, `read:user`

#### Creating a GitHub OAuth App

Go to GitHub → Settings → Developer Settings → OAuth Apps → New OAuth App

- Homepage URL: `http://localhost:3000`
- Callback URL: `http://localhost:7007/api/auth/github/handler/frame`

### 4. Start the development server

```bash
yarn dev
```

- Frontend: http://localhost:3000
- Backend: http://localhost:7007

---

## AWS Deployment

### 1. Bootstrap Terraform backend

Creates the S3 bucket and DynamoDB table for Terraform state:

```bash
cd infrastructure
chmod +x setup-backend.sh
./setup-backend.sh
```

### 2. Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
environment = "dev"
aws_region  = "us-east-1"
db_username = "backstage"
db_password = "your-secure-password"

db_password_secret_arn          = "arn:aws:secretsmanager:..."
github_token_secret_arn         = "arn:aws:secretsmanager:..."
auth_github_client_id_arn       = "arn:aws:secretsmanager:..."
auth_github_client_secret_arn   = "arn:aws:secretsmanager:..."
```

> Never commit `terraform.tfvars` to version control.

### 3. Create secrets in AWS Secrets Manager

```bash
aws secretsmanager create-secret \
  --name backstage/db-password \
  --secret-string "your-db-password"

aws secretsmanager create-secret \
  --name backstage/github-token \
  --secret-string "ghp_your_token"

aws secretsmanager create-secret \
  --name backstage/github-client-id \
  --secret-string "your_oauth_client_id"

aws secretsmanager create-secret \
  --name backstage/github-client-secret \
  --secret-string "your_oauth_client_secret"
```

### 4. Deploy infrastructure

```bash
terraform init
terraform plan
terraform apply
```

Outputs after apply:

```
backstage_url      = "http://your-alb.us-east-1.elb.amazonaws.com"
ecr_repository_url = "your-account.dkr.ecr.us-east-1.amazonaws.com/dev-backstage"
ecs_cluster_name   = "dev-backstage-cluster"
```

### 5. Build and push Docker image

```bash
cd ../developer-portal

# Build
yarn build:backend
docker build -f packages/backend/Dockerfile -t backstage .

# Authenticate with ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Tag and push
docker tag backstage YOUR_ECR_URL:latest
docker push YOUR_ECR_URL:latest
```

### 6. Update GitHub OAuth callback URL

Go to your GitHub OAuth App and update the callback URL:

```
http://your-alb.us-east-1.elb.amazonaws.com/api/auth/github/handler/frame
```

### 7. Deploy ECS service

```bash
aws ecs update-service \
  --cluster dev-backstage-cluster \
  --service dev-backstage \
  --force-new-deployment
```

---

## Self-Service Templates

The portal includes a microservice template that creates:

1. A GitHub repository with CI/CD pipeline
2. A `catalog-info.yaml` for automatic catalog registration
3. A GitHub Actions workflow

To use: navigate to **Create...** in the portal sidebar.

To add your own templates, add them to `examples/templates/` and register them in `app-config.yaml`.

---

## Project Structure

```
.
├── developer-portal/          # Backstage application
│   ├── app-config.yaml        # Base configuration
│   ├── app-config.production.yaml  # Production overrides
│   ├── examples/
│   │   └── templates/
│   │       └── microservice/  # Self-service microservice template
│   └── packages/
│       ├── app/               # React frontend
│       └── backend/           # Node.js backend
└── infrastructure/            # Terraform
    ├── modules/
    │   ├── vpc/
    │   ├── alb/
    │   ├── rds/
    │   └── ecs/
    └── setup-backend.sh
```

---

## Security Notes

- All secrets stored in AWS Secrets Manager — never in code
- ECS and RDS run in private subnets — only ALB is public
- RDS requires SSL connections
- One NAT Gateway per AZ for high availability
- ECR image scanning enabled on push

---

## License

MIT
