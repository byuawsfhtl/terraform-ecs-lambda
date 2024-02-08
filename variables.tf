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

variable "ecr_repo" {
  type = object({
    name           = string,
    repository_url = string
  })
  description = "The ECR repository that contains the image for the lambda functions."
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
variable "ecs_environment_variables" {
  type        = map(string)
  description = "The environment variables to set on the ECS task."
  default     = {}
}
variable "ecs_policies" {
  type        = list(string)
  description = "List of IAM Policy ARNs to attach to the ECS task."
  default     = []
}
variable "ecs_cpu" {
  type        = number
  description = "The number of CPU units to reserve for the task."
  default     = 256
}
variable "ecs_memory" {
  type        = number
  description = "The amount of memory (in MiB) to reserve for the task."
  default     = 512
}

variable "lambda_environment_variables" {
  type        = map(string)
  description = "The environment variables to set on the Lambda functions."
  default     = {}
}
variable "lambda_endpoint_definitions" {
  type = list(object({
    path_part       = string
    allowed_headers = optional(string)

    method_definitions = list(object({
      http_method = string
      command     = list(string)
      timeout     = optional(number)
    }))
  }))
  description = "The definitions for each lambda function."
}
variable "lambda_policies" {
  type        = list(string)
  description = "List of IAM Policy ARNs to attach to the task execution policy."
  default     = []
}
