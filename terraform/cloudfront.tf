resource "aws_cloudfront_distribution" "web" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.environment}-web-distribution"
  default_root_object = "index.html"

  origin {
    domain_name = aws_lb.web.dns_name
    origin_id   = "${var.environment}-web-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.environment}-web-alb"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = var.disable_cloudfront_caching ? 0 : 0
    default_ttl            = var.disable_cloudfront_caching ? 0 : 3600
    max_ttl                = var.disable_cloudfront_caching ? 0 : 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.environment}-web-distribution"
    Environment = var.environment
  }
}

