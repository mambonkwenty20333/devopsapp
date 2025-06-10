terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "devops_hilltop_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                        = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    Environment                                 = var.environment
    Project                                     = "devops-hilltop"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "devops_hilltop_igw" {
  vpc_id = aws_vpc.devops_hilltop_vpc.id

  tags = {
    Name        = "${var.cluster_name}-igw"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet" {
  count = 2

  vpc_id                  = aws_vpc.devops_hilltop_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.cluster_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    Environment                                 = var.environment
    Project                                     = "devops-hilltop"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet" {
  count = 2

  vpc_id            = aws_vpc.devops_hilltop_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                        = "${var.cluster_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    Environment                                 = var.environment
    Project                                     = "devops-hilltop"
  }
}

# NAT Gateway Elastic IPs
resource "aws_eip" "nat_gateway_eip" {
  count = 2

  domain = "vpc"
  depends_on = [aws_internet_gateway.devops_hilltop_igw]

  tags = {
    Name        = "${var.cluster_name}-nat-eip-${count.index + 1}"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "nat_gateway" {
  count = 2

  allocation_id = aws_eip.nat_gateway_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name        = "${var.cluster_name}-nat-gateway-${count.index + 1}"
    Environment = var.environment
    Project     = "devops-hilltop"
  }

  depends_on = [aws_internet_gateway.devops_hilltop_igw]
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devops_hilltop_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_hilltop_igw.id
  }

  tags = {
    Name        = "${var.cluster_name}-public-rt"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}

# Private Route Tables
resource "aws_route_table" "private_rt" {
  count = 2

  vpc_id = aws_vpc.devops_hilltop_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    Name        = "${var.cluster_name}-private-rt-${count.index + 1}"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_rta" {
  count = 2

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rta" {
  count = 2

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster_sg" {
  name_prefix = "${var.cluster_name}-cluster-sg"
  vpc_id      = aws_vpc.devops_hilltop_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-cluster-sg"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}

# Security Group for EKS Worker Nodes
resource "aws_security_group" "eks_nodes_sg" {
  name_prefix = "${var.cluster_name}-nodes-sg"
  vpc_id      = aws_vpc.devops_hilltop_vpc.id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  # NodePort access
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-nodes-sg"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-cluster-role"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}

# Attach required policies to EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-node-group-role"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}

# Attach required policies to EKS node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "devops_hilltop" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.private_subnet[*].id, aws_subnet.public_subnet[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
  }

  # Enable logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
    Project     = "devops-hilltop"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks_cluster_log_group,
  ]
}

# CloudWatch Log Group for EKS Cluster
resource "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = {
    Name        = "${var.cluster_name}-log-group"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}

# EKS Node Group
resource "aws_eks_node_group" "devops_hilltop_nodes" {
  cluster_name    = aws_eks_cluster.devops_hilltop.name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = aws_subnet.private_subnet[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name        = "${var.cluster_name}-workers"
    Environment = var.environment
    Project     = "devops-hilltop"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
}

# EKS Add-ons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.devops_hilltop.name
  addon_name   = "vpc-cni"

  tags = {
    Name        = "${var.cluster_name}-vpc-cni"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.devops_hilltop.name
  addon_name   = "coredns"

  depends_on = [aws_eks_node_group.devops_hilltop_nodes]

  tags = {
    Name        = "${var.cluster_name}-coredns"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.devops_hilltop.name
  addon_name   = "kube-proxy"

  tags = {
    Name        = "${var.cluster_name}-kube-proxy"
    Environment = var.environment
    Project     = "devops-hilltop"
  }
}