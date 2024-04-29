provider "aws" {
  region = var.region
}

# module "lib" {
#   source = "../lib/"
# }

## Save tfstate file in the S3 Bucket
terraform {
  backend "s3" {
    bucket = "coinhabit-bucket-for-tfstate"
    key    = "ecs-alb/terraform.tfstate"
    region = "ap-south-1"
  }
}

## Created ecs Taskexecution role
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "${var.name}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

## Assign IAM Policy
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


## ecs Cluster
resource "aws_ecs_cluster""ecs-cluster" {
  name = "${var.name}-ecs-cluster"
}


## ecs Task-definition
resource "aws_ecs_task_definition" "ecs-task-definition" {
  family                   = "${var.name}-task"
   requires_compatibilities = ["FARGATE"]
   cpu    = var.task_definition_cpu
   memory = var.task_definition_memory
  container_definitions    = jsonencode([{
    name   = "${var.name}-task"
    image  = var.image
    cpu       = var.container_cpu
    memory    = var.container_memory
    portMappings = [
        {
          containerPort = var.task_container_port
          hostPort      = var.task_host_port
        }
    ]
  }])
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

## ecs Service
resource "aws_ecs_service" "ecs-service" {
  name = "${var.name}-ecs-service"
  cluster = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.ecs-task-definition.arn
  launch_type = "FARGATE"
  desired_count = 1

  network_configuration {
    security_groups = ["${aws_security_group.service_security_group.id}"]
    assign_public_ip = true
    subnets         = ["subnet-08fbf2b4c90f7ccb3", "subnet-075c672bce4e7dd35"]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name = aws_ecs_task_definition.ecs-task-definition.family
    container_port = var.task_container_port
  }
}

## Security Group
resource "aws_security_group" "service_security_group" {
  vpc_id = "vpc-05508e4c00dff94bc"
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.lb_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.name}-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_security_group.id}"]
  subnets            = ["subnet-08fbf2b4c90f7ccb3", "subnet-075c672bce4e7dd35"]

  tags = {
    Name = var.name
  }
}


## lb Security Group
resource "aws_security_group" "lb_security_group" {
  vpc_id = "vpc-05508e4c00dff94bc"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Target Group
resource  "aws_lb_target_group" "alb_target_group" {
  name               = "${var.name}-tg"
  port               = 80
  protocol           = "HTTP"
  target_type        = "ip"
  vpc_id             = "vpc-05508e4c00dff94bc"
 


  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    path                = "/"
  }
    depends_on = [aws_lb.alb]

}

## Listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    redirect {
      port        = "5020"
      protocol    = "HTTP"
      status_code = "HTTP_301" 
    }
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

