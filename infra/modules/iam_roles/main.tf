data "aws_iam_policy_document" "mediaconvert_assume_role" {
  statement {
    sid     = "AllowMediaConvertAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["mediaconvert.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mediaconvert_service" {
  name               = "${var.name_prefix}-mediaconvert-role"
  assume_role_policy = data.aws_iam_policy_document.mediaconvert_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "mediaconvert_permissions" {
  statement {
    sid    = "ReadMasterUploads"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = [
      var.master_bucket_arn,
      "${var.master_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "WriteHlsOutputs"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
    ]
    resources = [
      var.hls_bucket_arn,
      "${var.hls_bucket_arn}/*",
    ]
  }

  dynamic "statement" {
    for_each = var.include_cloudwatch_logs_permissions ? [1] : []

    content {
      sid    = "WriteMediaConvertLogs"
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      resources = ["*"]
    }
  }
}

resource "aws_iam_role_policy" "mediaconvert_permissions" {
  name   = "${var.name_prefix}-mediaconvert-policy"
  role   = aws_iam_role.mediaconvert_service.id
  policy = data.aws_iam_policy_document.mediaconvert_permissions.json
}

data "aws_iam_policy_document" "rails_app_permissions" {
  statement {
    sid    = "MediaConvertAccess"
    effect = "Allow"
    actions = [
      "mediaconvert:CreateJob",
      "mediaconvert:GetJob",
      "mediaconvert:ListJobs",
      "mediaconvert:DescribeEndpoints",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "MasterUploadAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
    ]
    resources = [
      var.master_bucket_arn,
      "${var.master_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "ReadHlsOutputs"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]
    resources = [
      var.hls_bucket_arn,
      "${var.hls_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "ReadCloudFrontPrivateKeySecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [var.cloudfront_private_key_secret_arn]
  }
}

resource "aws_iam_policy" "rails_app" {
  name   = "${var.name_prefix}-rails-app-policy"
  policy = data.aws_iam_policy_document.rails_app_permissions.json
  tags   = var.tags
}
