variable "project_name" {
  type        = string
  description = "The name of the project in TitleCase."
}
variable "app_name" {
  type        = string
  description = "The name of the project in kebab-case."
}

variable "env" {
  type        = string
  description = "The branch being deployed."
}

variable "ecr_repo_name" {
  type        = string
  description = "The name of the ECR repository that contains the Docker images."
}
variable "image_tag" {
  type        = string
  description = "The image tag for the Docker images (the timestamp)."
}

variable "ecs_command" {
  type        = list(string)
  description = "The entry point for the Docker image used on the ECS task."
  default     = []
}
variable "ecs_policies" {
  type        = list(string)
  description = "List of IAM Policy ARNs to attach to the ECS task."
  default     = []
}

variable "lambda_function_definitions" {
  type = list(object({
    path_part       = string
    http_method     = string
    command         = list(string)
    allowed_headers = optional(string)
    timeout         = optional(number)
  }))
  description = "The definitions for each lambda function."
}
variable "lambda_policies" {
  type        = list(string)
  description = "List of IAM Policy ARNs to attach to the task execution policy."
  default     = []
}
