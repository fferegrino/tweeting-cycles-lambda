terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }

    null = {
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"

  backend "s3" {
    bucket = "feregrino-terraform-states"
    key    = "lambda-cycles-final"
    region = "eu-west-1"
  }
}

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

data "aws_caller_identity" "current_identity" {}

locals {
  account_id          = data.aws_caller_identity.current_identity.account_id
  prefix              = "lambda-cycles-final"
  ecr_repository_name = "${local.prefix}-image-repo"
  region              = "eu-west-1"
  ecr_image_tag       = "latest"
  minutes             = "30"
}

data "aws_secretsmanager_secret" "twitter_secrets" {
  arn = "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:lambda/cycles/twitter-2GMvKu"
}

data "aws_secretsmanager_secret_version" "current_twitter_secrets" {
  secret_id = data.aws_secretsmanager_secret.twitter_secrets.id
}

resource "aws_ecr_repository" "lambda_image" {
  name                 = local.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "null_resource" "ecr_image" {
  triggers = {
    python_file_1 = filemd5("../src/app.py")
    python_file_2 = filemd5("../src/plot.py")
    python_file_3 = filemd5("../src/tweeter.py")
    python_file_4 = filemd5("../src/download.py")
    requirements  = filemd5("../requirements.txt")
    docker_file   = filemd5("../Dockerfile")
  }
  provisioner "local-exec" {
    command = <<EOF
           aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${local.region}.amazonaws.com
           docker tag lambda-cycles ${aws_ecr_repository.lambda_image.repository_url}:${local.ecr_image_tag}
           docker push ${aws_ecr_repository.lambda_image.repository_url}:${local.ecr_image_tag}
       EOF
  }
}

data "aws_ecr_image" "lambda_image" {
  depends_on = [
    null_resource.ecr_image
  ]
  repository_name = local.ecr_repository_name
  image_tag       = local.ecr_image_tag
}

resource "aws_iam_role" "lambda" {
  name               = "${local.prefix}-lambda-role"
  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Action": "sts:AssumeRole",
           "Principal": {
               "Service": "lambda.amazonaws.com"
           },
           "Effect": "Allow"
       }
   ]
}
 EOF
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "CreateCloudWatchLogs"
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${local.prefix}-lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_lambda_function" "lambda" {
  depends_on = [
    null_resource.ecr_image
  ]
  function_name = "${local.prefix}-lambda"
  role          = aws_iam_role.lambda.arn
  timeout       = 300
  image_uri     = "${aws_ecr_repository.lambda_image.repository_url}@${data.aws_ecr_image.lambda_image.id}"
  package_type  = "Image"
  environment {
    variables = {
      API_KEY             = jsondecode(data.aws_secretsmanager_secret_version.current_twitter_secrets.secret_string)["API_KEY"]
      API_SECRET          = jsondecode(data.aws_secretsmanager_secret_version.current_twitter_secrets.secret_string)["API_SECRET"]
      ACCESS_TOKEN        = jsondecode(data.aws_secretsmanager_secret_version.current_twitter_secrets.secret_string)["ACCESS_TOKEN"]
      ACCESS_TOKEN_SECRET = jsondecode(data.aws_secretsmanager_secret_version.current_twitter_secrets.secret_string)["ACCESS_TOKEN_SECRET"]
    }
  }
}

resource "aws_cloudwatch_event_rule" "every_x_minutes" {
  name                = "${local.prefix}-event-rule-lambda"
  description         = "Fires every ${local.minutes} minutes"
  schedule_expression = "cron(0/${local.minutes} * * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_every_x_minutes" {
  rule      = aws_cloudwatch_event_rule.every_x_minutes.name
  target_id = "lambda"
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_x_minutes.arn
}
