data "aws_caller_identity" "current" {}

resource "aws_iam_role" "omnistrate-bootstrap-role" {
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-west-2.amazonaws.com/id/9AEF0C846C22DEAEFDDD1F98C6AB9FEA:sub": "system:serviceaccount:bootstrap:bootstrap-sa"
        }
      },
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/9AEF0C846C22DEAEFDDD1F98C6AB9FEA"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  managed_policy_arns  = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/omnistrate-bootstrap-policy"]
  max_session_duration = "3600"
  name                 = "omnistrate-bootstrap-role"
  path                 = "/"
}

resource "aws_iam_role" "omnistrate-ec2-node-group-iam-role" {
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Sid": ""
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  inline_policy {
    name   = "eks-nodegroup-describe-policy"
    policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":\"eks:DescribeNodegroup\",\"Effect\":\"Allow\",\"Resource\":\"*\",\"Sid\":\"VisualEditor0\"}]}"
  }

  managed_policy_arns  = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy", "arn:aws:iam::aws:policy/AutoScalingFullAccess"]
  max_session_duration = "3600"
  name                 = "omnistrate-ec2-node-group-iam-role"
  path                 = "/"
}

resource "aws_iam_role" "omnistrate-eks-iam-role" {
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Sid": ""
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  managed_policy_arns  = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy", "arn:aws:iam::aws:policy/AmazonEKSServicePolicy", "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"]
  max_session_duration = "3600"
  name                 = "omnistrate-eks-iam-role"
  path                 = "/"
}

output "bootstrap-role" {
  value = aws_iam_role.omnistrate-bootstrap-role.arn
}
