#############################  ECR Repository  #################################

# Create ECR Repository



resource "aws_ecr_repository" "my_ecr_repo" {
  name = "${var.environment_name}-ecr-repo"
  image_tag_mutability = "IMMUTABLE" # You can customize this as needed


  tags = {
    Name = "${var.environment_name}-ecr-repo"
  }

 

  image_scanning_configuration {
     scan_on_push = true
   }
}


   


###############################  ECS Cluster ############################################


# Create ECS Cluster
resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = "${var.environment_name}-ecs-cluster"

  setting {
      name  = "containerInsights"
      value = "enabled"
    }
}


#############################  ECS Roles and Permissions ##################################

# Create ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment_name}-ecs-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach Policies to ECS Task Execution Role (adjust policies as needed)

#Policy for cloudwatch logs
resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess" # Attach policies as needed
  role       = aws_iam_role.ecs_execution_role.name

}

#Policy for ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment_ECS" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" # Amazon ECS managed policy
  role       = aws_iam_role.ecs_execution_role.name
}


###############################  ECS Task Definition ############################################

# Create ECS Task Definition
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "${var.environment_name}-task-family"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "3072"

  # ECS Container
  container_definitions = jsonencode([
    {
      name  = var.container_name
      image = aws_ecr_repository.my_ecr_repo.repository_url
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        },
      ]
    },
  ])
}



#############################  ECR Security Group  #################################



# Create a security group for ECS tasks
resource "aws_security_group" "ecs_security_group" {
  vpc_id = aws_vpc.my_vpc.id
  description = "Allow container and http connection"

  egress {
    description = "Allowed online availability "
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
    
  }

  ingress {
    description = "Allow load balancer to access container on port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
#IP of the load balancer accessing the container
    cidr_blocks = ["0.0.0.0/0"]                       
  }

  ingress {
    description = "Allow load balancer to be accessed by internet users "
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"


    cidr_blocks = ["0.0.0.0/0"]                   #Available on the internet
  }

  tags = {
    Name = "${var.environment_name}-ecs-security-group"
  }
}

###############################  ECS Service Task ############################################
# ECS Service
resource "aws_ecs_service" "my_service" {
  name            = "${var.environment_name}-ecs-service-task"
  cluster         = aws_ecs_cluster.my_ecs_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1


  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "studio-ghibli-container"
    container_port   = 3000   #Change this if application container use different port
  }

  network_configuration {
    subnets         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups = [aws_security_group.ecs_security_group.id]

  }
}

#############################  Load Balancer #############################################

# Application Load Balancer

resource "aws_lb" "my_alb" {
  name               = "${var.environment_name}-load-balacer"

  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_security_group.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

}

# ALB Target Group
resource "aws_lb_target_group" "my_target_group" {
  name        = "${var.environment_name}-my-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.my_vpc.id
}

# ALB Listener
resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80

  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}