# resource "aws_iam_role_policy_attachment" "AWSServiceRoleForAmazonEKSNodegroup_AWSServiceRoleForAmazonEKSNodegroup" {
#   policy_arn = "arn:aws:iam::aws:policy/aws-service-role/AWSServiceRoleForAmazonEKSNodegroup"
#   role       = "AWSServiceRoleForAmazonEKSNodegroup"
# }

# resource "aws_iam_role_policy_attachment" "AWSServiceRoleForAmazonEKS_AmazonEKSServiceRolePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/aws-service-role/AmazonEKSServiceRolePolicy"
#   role       = "AWSServiceRoleForAmazonEKS"
# }

# resource "aws_iam_role_policy_attachment" "AWSServiceRoleForAutoScaling_AutoScalingServiceRolePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/aws-service-role/AutoScalingServiceRolePolicy"
#   role       = "AWSServiceRoleForAutoScaling"
# }

resource "aws_iam_role_policy_attachment" "omnistrate-bootstrap-role_omnistrate-bootstrap-policy" {
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/omnistrate-bootstrap-policy"
  role       = "omnistrate-bootstrap-role"
  depends_on = [
    aws_iam_policy.omnistrate-bootstrap-policy,
    aws_iam_policy.omnistrate-bootstrap-permissions-boundary
  ]
}

resource "aws_iam_role_policy_attachment" "omnistrate-ec2-node-group-iam-role_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "omnistrate-ec2-node-group-iam-role"
  depends_on = [
    aws_iam_role.omnistrate-ec2-node-group-iam-role
  ]
}

resource "aws_iam_role_policy_attachment" "omnistrate-ec2-node-group-iam-role_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "omnistrate-ec2-node-group-iam-role"
  depends_on = [
    aws_iam_role.omnistrate-ec2-node-group-iam-role
  ]
}

resource "aws_iam_role_policy_attachment" "omnistrate-ec2-node-group-iam-role_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "omnistrate-ec2-node-group-iam-role"
  depends_on = [
    aws_iam_role.omnistrate-ec2-node-group-iam-role
  ]
}

resource "aws_iam_role_policy_attachment" "omnistrate-ec2-node-group-iam-role_AutoScalingFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = "omnistrate-ec2-node-group-iam-role"
  depends_on = [
    aws_iam_role.omnistrate-ec2-node-group-iam-role
  ]
}

resource "aws_iam_role_policy_attachment" "omnistrate-eks-iam-role_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "omnistrate-eks-iam-role"
  depends_on = [
    aws_iam_role.omnistrate-eks-iam-role
  ]
}

resource "aws_iam_role_policy_attachment" "omnistrate-eks-iam-role_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "omnistrate-eks-iam-role"
  depends_on = [
    aws_iam_role.omnistrate-eks-iam-role
  ]
}

resource "aws_iam_role_policy_attachment" "omnistrate-eks-iam-role_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "omnistrate-eks-iam-role"
  depends_on = [
    aws_iam_role.omnistrate-eks-iam-role
  ]
}

resource "aws_iam_role_policy_attachment" "omnistrate-eks-iam-role_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = "omnistrate-eks-iam-role"
  depends_on = [
    aws_iam_role.omnistrate-eks-iam-role
  ]
}
