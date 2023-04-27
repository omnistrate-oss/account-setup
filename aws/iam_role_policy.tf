resource "aws_iam_role_policy" "omnistrate-ec2-node-group-iam-role_eks-nodegroup-describe-policy" {
  name = "eks-nodegroup-describe-policy"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": "eks:DescribeNodegroup",
      "Effect": "Allow",
      "Resource": "*",
      "Sid": "VisualEditor0"
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  role = "omnistrate-ec2-node-group-iam-role"
  depends_on = [
    aws_iam_role.omnistrate-ec2-node-group-iam-role
  ]
}
