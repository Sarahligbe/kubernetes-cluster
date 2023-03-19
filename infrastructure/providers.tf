terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.57.1"
    }

    helm = {
      source = "hashicorp/helm"
      version = "2.9.0"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.18.1"
    }
  }

  backend "s3" {
    bucket         = "ofure-terraform-state"
    key            = "backend/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

}

provider "aws" {
  region = "us-east-1"
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}


provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
   }
 }
