variable "name" {
  type = string
  default = "coinbase"
  description = "The name prefix for the resource."
}

variable "region" {
  type = string
  default = "ap-south-1"
  description = "Specifies the region"
}

variable "image" {
    type = string
    default = "190864224489.dkr.ecr.ap-south-1.amazonaws.com/cooinbase"
    description = "The image to use for the container."
}



variable "task_container_port" {
  description = "The port number on the container that is bound to the user-specified or automatically assigned host port"
  type        = number
  default     = 5020
}

variable "task_host_port" {
  description = "The port number on the container instance to reserve for your container."
  type        = number
  default     = 5020
}

variable "task_definition_cpu" {
  description = "Amount of CPU to reserve for the task."
  default     = 256
  type        = number
}

variable "task_definition_memory" {
  description = "The soft limit (in MiB) of memory to reserve for the task."
  default     = 512
  type        = number
}

variable "container_cpu" {
  description = "Amount of CPU to reserve for the task."
  default     = 256
  type        = number
}

variable "container_memory" {
  description = "The soft limit (in MiB) of memory to reserve for the task."
  default     = 512
  type        = number
}
