locals {
  domain  = (var.env == "prd") ? "rll.byu.edu" : "rll-dev.byu.edu"
  url     = lower("${var.project_name}.${local.domain}")
  api_url = "api.${local.url}"
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v4.0.0"
}

# ========== ECS ==========
module "ecs_fargate" {
  source = "github.com/byuawsfhtl/terraform-ecs-fargate?ref=prd"

  app_name = var.project_name
  primary_container_definition = {
    name                  = "${var.project_name}Container"
    image                 = "${var.ecr_repo.repository_url}:${var.app_name}-ecs-${var.image_tag}"
    command               = var.ecs_command
    environment_variables = var.ecs_environment_variables
    secrets               = {}
  }
  event_role_arn                = module.acs.power_builder_role.arn
  vpc_id                        = module.acs.vpc.id
  private_subnet_ids            = module.acs.private_subnet_ids
  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn

  task_cpu    = var.ecs_cpu
  task_memory = var.ecs_memory

  task_policies = concat(var.ecs_policies, [aws_iam_policy.s3_data_policy.arn])
}

# ========== API ==========
module "lambda_api" {
  source = "github.com/byuawsfhtl/terraform-lambda-api?ref=prd"

  project_name                 = var.project_name
  app_name                     = var.app_name
  domain                       = local.domain
  url                          = local.url
  api_url                      = local.api_url
  ecr_repo                     = var.ecr_repo
  image_tag                    = "lambda-${var.image_tag}"
  lambda_environment_variables = var.lambda_environment_variables
  lambda_endpoint_definitions  = var.lambda_endpoint_definitions
  function_policies            = concat(var.lambda_policies, [aws_iam_policy.ecs_template_policy.arn, aws_iam_policy.s3_data_policy.arn])
}

# ========== S3 Data Bucket ==========
resource "aws_s3_bucket" "data-bucket" {
  bucket = "${var.app_name}-data-${var.env}"
}

# ========== IAM Policies ==========
resource "aws_iam_policy" "ecs_template_policy" {
  name        = "${var.project_name}-template-ecs"
  description = "Permission to run the ${var.project_name} ecs task"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : "ecs:RunTask",
        Resource : "${module.ecs_fargate.task_definition.arn}"
      },
      {
        Effect : "Allow",
        Action : [
          "ecs:ListTasks",
          "ecs:ListTaskDefinitions",
          "ecs:DescribeTasks",
          "ec2:DescribeSecurityGroups",
          "iam:PassRole"
        ],
        # TODO: specify actual resources rather than assume all
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_data_policy" {
  name        = "${var.project_name}-data-s3"
  description = "Access to the S3 data bucket"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect : "Allow",
        Action : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Resource : [
          "${resource.aws_s3_bucket.data-bucket.arn}",
          "${resource.aws_s3_bucket.data-bucket.arn}/*"
        ]
      }
    ]
  })
}
