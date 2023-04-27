# Create an AWS IAM OIDC provider
resource "aws_iam_openid_connect_provider" "oidc" {
  url = "https://oidc.eks.us-west-2.amazonaws.com/id/DDD24EA1057FF9C5F85C434C444F1B80"
  client_id_list = [
    "sts.amazonaws.com"
  ]
  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
  ]
}
