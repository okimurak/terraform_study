
// -------------------- S3 ---------------------

variable accountid {}

resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-hogehoge"

  lifecycle_rule {
    enabled = true
    expiration {
      days = "10"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = [var.accountid]
    }
  }
}

// -------------------- Networking ---------------------

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "example"
  }
}

resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.65.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.66.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
}

resource "aws_eip" "nat_gateway_0" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

resource "aws_eip" "nat_gateway_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.example]
}

resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

module "example_sg" {
  source      = "./modules/security_group"
  name        = "module-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

// -------------------- ALB ---------------------

module "http_sg" {
  source      = "./modules/security_group"
  name        = "http-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./modules/security_group"
  name        = "https-sg"
  vpc_id      = aws_vpc.example.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./modules/security_group"
  name        = "http-redirect-sg"
  vpc_id      = aws_vpc.example.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "example" {
  name                       = "example"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = true

  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is http."
      status_code  = "200"
    }
  }
}

// Dot TKで無料ドメインを作成し、Route 53のホストゾーンに登録する

resource "aws_route53_zone" "example" {
  name = "sample-yappo-terraform.tk"
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.zone_id
  name    = aws_route53_zone.example.name
  type    = "A"

  alias {
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "example" {
  domain_name               = aws_route53_zone.example.name
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "example_certificate" {
  name    = aws_acm_certificate.example.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.example.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.example.domain_validation_options[0].resource_record_value]
  zone_id = aws_route53_zone.example.id
  ttl     = 60
}

//resource "aws_acm_certificate_validation" "example" {
//  certificate_arn = aws_acm_certificate.example.arn
//  validation_record_fqdns = [aws_route53_record.example_certificate.fqdn]
//}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.example.arn
  ssl_policy        = "ELBSecurityPilicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is Https."
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "example" {
  name = "example"
  vpc_id = aws_vpc.example.id
  target_type = "ip"
  port = 80
  protocol = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.example]
}

resource "aws_lb_listener_rule" "example" {
  listener_arn = aws_lb_listener.https.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  condition {
    field = "path-pattern"
    values = ["/*"]
  }
}