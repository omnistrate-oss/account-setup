resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name = "AWSLoadBalancerControllerIAMPolicy"
  path = "/"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "iam:CreateServiceLinkedRole"
      ],
      "Condition": {
        "StringEquals": {
          "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
        }
      },
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAddresses",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeVpcs",
        "ec2:DescribeVpcPeeringConnections",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeTags",
        "ec2:GetCoipPoolUsage",
        "ec2:DescribeCoipPools",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeListenerCertificates",
        "elasticloadbalancing:DescribeSSLPolicies",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:DescribeTags"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "cognito-idp:DescribeUserPoolClient",
        "acm:ListCertificates",
        "acm:DescribeCertificate",
        "iam:ListServerCertificates",
        "iam:GetServerCertificate",
        "waf-regional:GetWebACL",
        "waf-regional:GetWebACLForResource",
        "waf-regional:AssociateWebACL",
        "waf-regional:DisassociateWebACL",
        "wafv2:GetWebACL",
        "wafv2:GetWebACLForResource",
        "wafv2:AssociateWebACL",
        "wafv2:DisassociateWebACL",
        "shield:GetSubscriptionState",
        "shield:DescribeProtection",
        "shield:CreateProtection",
        "shield:DeleteProtection"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:CreateSecurityGroup"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:CreateTags"
      ],
      "Condition": {
        "Null": {
          "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
        },
        "StringEquals": {
          "ec2:CreateAction": "CreateSecurityGroup"
        }
      },
      "Effect": "Allow",
      "Resource": "arn:aws:ec2:*:*:security-group/*"
    },
    {
      "Action": [
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Condition": {
        "Null": {
          "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
          "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
        }
      },
      "Effect": "Allow",
      "Resource": "arn:aws:ec2:*:*:security-group/*"
    },
    {
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DeleteSecurityGroup"
      ],
      "Condition": {
        "Null": {
          "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
        }
      },
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateTargetGroup"
      ],
      "Condition": {
        "Null": {
          "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
        }
      },
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:DeleteRule"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ],
      "Condition": {
        "Null": {
          "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
          "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
        }
      },
      "Effect": "Allow",
      "Resource": [
        "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
      ]
    },
    {
      "Action": [
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
        "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
        "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
        "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
      ]
    },
    {
      "Action": [
        "elasticloadbalancing:AddTags"
      ],
      "Condition": {
        "Null": {
          "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
        },
        "StringEquals": {
          "elasticloadbalancing:CreateAction": [
            "CreateTargetGroup",
            "CreateLoadBalancer"
          ]
        }
      },
      "Effect": "Allow",
      "Resource": [
        "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
      ]
    },
    {
      "Action": [
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:DeleteTargetGroup"
      ],
      "Condition": {
        "Null": {
          "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
        }
      },
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
    },
    {
      "Action": [
        "elasticloadbalancing:SetWebAcl",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:AddListenerCertificates",
        "elasticloadbalancing:RemoveListenerCertificates",
        "elasticloadbalancing:ModifyRule"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_policy" "omnistrate-bootstrap-permissions-boundary" {
  name = "omnistrate-bootstrap-permissions-boundary"
  path = "/"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "iam:DetachRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy"
      ],
      "Condition": {
        "ForAnyValue:StringLike": {
          "iam:PermissionsBoundary": "arn:aws:iam::*:policy/omnistrate-bootstrap-permissions-boundary"
        }
      },
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:UpdateAssumeRolePolicy",
        "iam:GetPolicyVersion",
        "iam:CreateServiceSpecificCredential",
        "iam:ListRoleTags",
        "iam:UpdateOpenIDConnectProviderThumbprint",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:ListServiceSpecificCredentials",
        "iam:AddRoleToInstanceProfile",
        "iam:ListAttachedRolePolicies",
        "iam:ListOpenIDConnectProviderTags",
        "iam:ListRolePolicies",
        "iam:DeleteOpenIDConnectProvider",
        "iam:ListPolicies",
        "iam:UpdateServiceSpecificCredential",
        "iam:GetRole",
        "iam:GetPolicy",
        "iam:RemoveClientIDFromOpenIDConnectProvider",
        "iam:ListEntitiesForPolicy",
        "iam:DeleteRole",
	"iam:DeletePolicy",
        "iam:UpdateRoleDescription",
        "iam:GetUserPolicy",
        "iam:ListGroupsForUser",
        "ec2:*",
        "iam:DeleteServiceLinkedRole",
        "iam:GetGroupPolicy",
        "iam:GetOpenIDConnectProvider",
        "eks:*",
        "iam:GetRolePolicy",
        "iam:CreateInstanceProfile",
        "iam:UntagRole",
        "iam:TagRole",
	"iam:TagPolicy",
        "iam:ListPoliciesGrantingServiceAccess",
        "iam:ResetServiceSpecificCredential",
        "iam:ListInstanceProfileTags",
        "iam:GetServiceLinkedRoleDeletionStatus",
        "iam:PassRole",
        "iam:ListPolicyTags",
        "iam:CreatePolicyVersion",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:ListRoles",
        "elasticloadbalancing:*",
        "iam:ListUserPolicies",
        "iam:ListInstanceProfiles",
        "iam:CreateOpenIDConnectProvider",
        "iam:CreatePolicy",
        "iam:CreateServiceLinkedRole",
        "iam:ListPolicyVersions",
        "iam:ListOpenIDConnectProviders",
        "iam:UntagPolicy",
        "iam:UpdateRole",
        "iam:UntagOpenIDConnectProvider",
        "iam:AddClientIDToOpenIDConnectProvider",
        "iam:UntagInstanceProfile",
        "iam:DeleteServiceSpecificCredential",
        "iam:TagOpenIDConnectProvider",
        "iam:DeletePolicyVersion",
        "iam:TagInstanceProfile",
        "iam:SetDefaultPolicyVersion",
        "route53:*",
        "s3:*",
        "kms:*", 
        "secretsmanager:*",
        "kafkaconnect:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
          "s3:*"
      ],
      "Resource": [
          "arn:aws:s3:::omnistrate-${data.aws_caller_identity.current.account_id}-dp-pulumi",
          "arn:aws:s3:::omnistrate-${data.aws_caller_identity.current.account_id}-dp-pulumi/*"
      ]
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_policy" "omnistrate-bootstrap-policy" {
  name = "omnistrate-bootstrap-policy"
  path = "/"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "iam:DetachRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy"
      ],
      "Condition": {
        "ForAnyValue:StringLike": {
          "iam:PermissionsBoundary": "arn:aws:iam::*:policy/omnistrate-bootstrap-permissions-boundary"
        }
      },
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:UpdateAssumeRolePolicy",
        "iam:GetPolicyVersion",
        "iam:CreateServiceSpecificCredential",
        "iam:ListRoleTags",
        "iam:UpdateOpenIDConnectProviderThumbprint",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:ListServiceSpecificCredentials",
        "iam:AddRoleToInstanceProfile",
        "iam:ListAttachedRolePolicies",
        "iam:ListOpenIDConnectProviderTags",
        "iam:ListRolePolicies",
        "iam:DeleteOpenIDConnectProvider",
        "iam:ListPolicies",
        "iam:UpdateServiceSpecificCredential",
        "iam:GetRole",
        "iam:GetPolicy",
        "iam:RemoveClientIDFromOpenIDConnectProvider",
        "iam:ListEntitiesForPolicy",
        "iam:DeleteRole",
        "iam:UpdateRoleDescription",
        "iam:GetUserPolicy",
        "iam:ListGroupsForUser",
        "ec2:*",
        "iam:DeleteServiceLinkedRole",
        "iam:GetGroupPolicy",
        "eks:*",
        "iam:GetOpenIDConnectProvider",
        "iam:GetRolePolicy",
        "iam:CreateInstanceProfile",
        "iam:UntagRole",
        "iam:TagRole",
        "iam:ListPoliciesGrantingServiceAccess",
        "iam:ResetServiceSpecificCredential",
        "iam:ListInstanceProfileTags",
        "iam:GetServiceLinkedRoleDeletionStatus",
        "iam:ListInstanceProfilesForRole",
        "iam:PassRole",
        "iam:ListPolicyTags",
        "iam:CreatePolicyVersion",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:ListRoles",
        "elasticloadbalancing:*",
        "iam:ListUserPolicies",
        "iam:ListInstanceProfiles",
        "iam:CreateOpenIDConnectProvider",
        "iam:CreatePolicy",
        "iam:CreateServiceLinkedRole",
        "iam:ListPolicyVersions",
        "iam:ListOpenIDConnectProviders",
        "iam:UntagPolicy",
        "iam:UpdateRole",
        "iam:UntagOpenIDConnectProvider",
        "iam:AddClientIDToOpenIDConnectProvider",
        "iam:UntagInstanceProfile",
        "iam:DeleteServiceSpecificCredential",
        "iam:TagOpenIDConnectProvider",
        "iam:DeletePolicyVersion",
        "iam:TagInstanceProfile",
        "iam:SetDefaultPolicyVersion"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": "autoscaling:*",
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
          "arn:aws:s3:::omnistrate-${data.aws_caller_identity.current.account_id}-dp-pulumi",
          "arn:aws:s3:::omnistrate-${data.aws_caller_identity.current.account_id}-dp-pulumi/*"
      ]
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_policy" "omnistrate-infrastructure-provisioning-policy" {
  name = "omnistrate-infrastructure-provisioning-policy"
  path = "/"

  policy = <<POLICY
{
  "Statement": [
	{
	    "Action": [
		"iam:Get*",
		"iam:List*"
	    ],
	    "Effect": "Allow",
	    "Resource": "*"
	},
	{
	    "Action": [
		"iam:GetRole",
		"iam:PassRole",
		"iam:ListAttachedRolePolicies"
	    ],
	    "Effect": "Allow",
	    "Resource": [
	        "arn:aws:iam::*:role/ows-ec2-node-group-role",
	        "arn:aws:iam::*:role/omnistrate-eks-iam-role",
	        "arn:aws:iam::*:role/omnistrate-ec2-node-group-iam-role",
	        "arn:aws:iam::*:role/aws-service-role/eks-nodegroup.amazonaws.com/AWSServiceRoleForAmazonEKSNodegroup"
	    ]
    	},
        {
            "Action": [
                "iam:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:iam::*:role/omnistrate/*", 
                "arn:aws:iam::*:policy/omnistrate/*"
            ]
        },
	{
	      "Action": [
	        "s3:*",
	        "ec2:*",
	        "elasticloadbalancing:*",
	        "eks:*"
	      ],
	      "Effect": "Allow",
	      "Resource": "*"
	}
  ],
  "Version": "2012-10-17"
}
POLICY
}
