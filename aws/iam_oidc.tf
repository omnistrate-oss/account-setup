# Create an AWS IAM OIDC provider
resource "aws_iam_openid_connect_provider" "oidc" {
  url = "https://oidc.eks.us-west-2.amazonaws.com/id/9AEF0C846C22DEAEFDDD1F98C6AB9FEA"
  client_id_list = [
    "sts.amazonaws.com"
  ]
  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
  ]
}
