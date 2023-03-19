#this module deploys the eks cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.10.0"

  cluster_name = var.cluster_name
  cluster_version = "1.25"

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access = true

  vpc_id = aws_vpc.main.id
  subnet_ids = [for value in aws_subnet.private_subnets: value.id]
  control_plane_subnet_ids = [for value in aws_subnet.intra_subnets: value.id]

  eks_managed_node_group_defaults = {
    disk_size = 30
    use_custom_launch_template = false
  }

  eks_managed_node_groups = {
      main = {
      desired_size = 2
      min_size     = 2
      max_size     = 5
      instance_types = [var.instance_type]
      capacity_type = "ON_DEMAND"
    }
    
  }
}


