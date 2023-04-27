data "aws_caller_identity" "current" {}

resource "aws_iam_service_linked_role" "AWSServiceRoleForAmazonEKS" {
  aws_service_name = "eks.amazonaws.com"
  description      = "Allows Amazon EKS to call AWS services on your behalf."
}

resource "aws_iam_service_linked_role" "AWSServiceRoleForAmazonEKSNodegroup" {
  aws_service_name = "eks-nodegroup.amazonaws.com"
  description      = "This policy allows Amazon EKS to create and manage Nodegroups"
}

resource "aws_iam_service_linked_role" "AWSServiceRoleForAutoScaling" {
  aws_service_name = "autoscaling.amazonaws.com"
  description      = "Default Service-Linked Role enables access to AWS Services and Resources used or managed by Auto Scaling"
}

resource "aws_iam_role" "omnistrate-bootstrap-role" {
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-west-2.amazonaws.com/id/DDD24EA1057FF9C5F85C434C444F1B80:sub": "system:serviceaccount:bootstrap:bootstrap-sa"
        }
      },
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/DDD24EA1057FF9C5F85C434C444F1B80"
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
