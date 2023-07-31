locals {
  domain  = (var.env == "prd") ? "rll.byu.edu" : "rll-dev.byu.edu"
  url     = lower("${var.project_name}.${local.domain}")
  api_url = "api.${local.url}"
}

data "aws_ecr_repository" "ecr_repo" {
  name = var.ecr_repo_name
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
    image                 = "${data.aws_ecr_repository.ecr_repo.repository_url}:${var.app_name}-ecs-${var.image_tag}"
    command               = var.ecs_command
    environment_variables = {}
    secrets               = {}
  }
  event_role_arn                = module.acs.power_builder_role.arn
  vpc_id                        = module.acs.vpc.id
  private_subnet_ids            = module.acs.private_subnet_ids
  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn

  task_policies = var.ecs_policies
}

# ========== API ==========
module "lambda_api" {
  source = "github.com/byuawsfhtl/terraform-lambda-api?ref=prd"

  project_name                = var.project_name
  app_name                    = var.app_name
  domain                      = local.domain
  url                         = local.url
  api_url                     = local.api_url
  ecr_repo_name               = var.ecr_repo_name
  image_tag                   = "lambda-${var.image_tag}"
  lambda_function_definitions = var.lambda_function_definitions
  function_policies           = concat(var.lambda_policies, [aws_iam_policy.ecs_policy.arn])
}

# ========== IAM Policies ==========
resource "aws_iam_policy" "ecs_policy" {
  name        = "${var.project_name}-ecs"
  description = "Permission to run the ${var.project_name} ecs task"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "ecs:RunTask"
        ],
        Resource : [
          "${module.ecs_fargate.task_definition.arn}"
        ]

      }
    ]
  })
}
