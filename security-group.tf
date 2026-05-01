resource "aws_security_group" "this" {
  name        = local.resource_name
  vpc_id      = local.vpc_id
  tags        = merge(local.tags, { Name = local.resource_name })
  description = "Managed by Terraform"
}

resource "aws_security_group_rule" "this-dns-tcp-to-world" {
  description       = "Allow job to communicate with any nameserver over TCP"
  security_group_id = aws_security_group.this.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 53
  to_port           = 53
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "this-dns-udp-to-world" {
  description       = "Allow job to communicate with any nameserver over UDP"
  security_group_id = aws_security_group.this.id
  type              = "egress"
  protocol          = "udp"
  from_port         = 53
  to_port           = 53
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "this-https-to-world" {
  description       = "Allow job to communicate with any server over HTTPS"
  security_group_id = aws_security_group.this.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

// Intra-VPC egress on any port/protocol so this pod can reach other pods and
// managed AWS services (e.g. RDS). Access to AWS services is restricted at
// those services' own security groups (ingress from this pod SG).
resource "aws_security_group_rule" "this-egress-to-vpc" {
  description       = "Allow all egress within the VPC for pod-to-pod and managed AWS services"
  security_group_id = aws_security_group.this.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = [local.vpc_cidr]
}

resource "kubernetes_manifest" "security_group_policy" {
  count = var.disable_security_group ? 0 : 1

  manifest = {
    apiVersion = "vpcresources.k8s.aws/v1beta1"
    kind       = "SecurityGroupPolicy"

    metadata = {
      name      = aws_security_group.this.name
      namespace = local.app_namespace
    }

    spec = {
      podSelector = {
        matchLabels = local.match_labels
      }
      securityGroups = {
        groupIds = [aws_security_group.this.id]
      }
    }
  }
}
