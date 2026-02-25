locals {
  origin_id = "hls-s3-origin"
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.name_prefix}-hls-oac"
  description                       = "OAC for ${var.name_prefix} HLS output bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_public_key" "this" {
  name        = "${var.name_prefix}-public-key"
  comment     = "Public key for signed cookies"
  encoded_key = var.cloudfront_public_key_pem
}

resource "aws_cloudfront_key_group" "this" {
  name    = "${var.name_prefix}-key-group"
  comment = "Trusted key group for HLS signed cookies"
  items   = [aws_cloudfront_public_key.this.id]
}

resource "aws_cloudfront_cache_policy" "hls" {
  name        = "${var.name_prefix}-hls-cache-policy"
  comment     = "Cache policy tuned for HLS playback"
  default_ttl = var.hls_default_ttl
  max_ttl     = var.hls_max_ttl
  min_ttl     = var.hls_min_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.name_prefix} HLS distribution"
  aliases         = var.aliases
  price_class     = var.price_class

  origin {
    domain_name              = var.hls_bucket_regional_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id
    compress         = true

    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.hls.id
    trusted_key_groups     = [aws_cloudfront_key_group.this.id]
  }

  ordered_cache_behavior {
    path_pattern           = "books/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.origin_id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.hls.id
    trusted_key_groups     = [aws_cloudfront_key_group.this.id]
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = length(var.aliases) == 0
    acm_certificate_arn            = length(var.aliases) > 0 ? var.acm_certificate_arn : null
    ssl_support_method             = length(var.aliases) > 0 ? "sni-only" : null
    minimum_protocol_version       = length(var.aliases) > 0 ? var.minimum_protocol_version : "TLSv1"
  }

  tags = var.tags
}

resource "aws_route53_record" "alias_a" {
  for_each = var.route53_zone_id == null ? toset([]) : toset(var.aliases)

  zone_id = var.route53_zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_aaaa" {
  for_each = var.route53_zone_id == null ? toset([]) : toset(var.aliases)

  zone_id = var.route53_zone_id
  name    = each.value
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
