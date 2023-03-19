cluster_name = "eks-project"
vpc_cidr_block = "172.19.0.0/16"
private_subnet_blocks = {
  priv_subnet_01 = {
    cidr = "172.19.0.0/19"
    az = "us-east-1a"
  }
  priv_subnet_02 = {
    cidr = "172.19.32.0/19"
    az = "us-east-1b"
  }
}
public_subnet_blocks = {
  pub_subnet_01 = {
    cidr = "172.19.64.0/19"
    az = "us-east-1a"
  }
  pub_subnet_02 = {
    cidr = "172.19.96.0/19"
    az = "us-east-1b"
  }
}
intra_subnet_blocks = {
  intra_subnet_01 = {
    cidr = "172.19.128.0/19"
    az = "us-east-1a"
  }
  intra_subnet_02 = {
    cidr = "172.19.160.0/19"
    az = "us-east-1b"
  }
}
domain = "sarahaligbe.me"
email = "sarahligbe12@gmail.com"
argocd-domain = "argocd.sarahaligbe.me"
grafana_domain = "graf.sarahaligbe.me"
prom_domain = "prom.sarahaligbe.me"
