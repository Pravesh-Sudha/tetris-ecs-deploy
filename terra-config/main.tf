# Create an ECS Cluster
resource "aws_ecs_cluster" "tetris_cluster" {
  name = "tetris-cluster"
  tags = {
    Name = "tetris-cluster"
  }
}

# Create an IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "tetrisEcsTaskExecutionRole"
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

# Attach the ECS task execution policy to the role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create an ECS Task Definition
resource "aws_ecs_task_definition" "tetris_task" {
  family                   = "tetris-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" 
  memory                   = "512" 
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "tetris"
      image     = "uzyexe/tetris:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
  tags = {
    Name = "tetris-task"
  }
}

# Create an ECS Service
resource "aws_ecs_service" "tetris_service" {
  name            = "tetris-service"
  cluster         = aws_ecs_cluster.tetris_cluster.id
  task_definition = aws_ecs_task_definition.tetris_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.tetris_ecs_sg.id]
    assign_public_ip = true
  }
  tags = {
    Name = "tetris-service"
  }
}