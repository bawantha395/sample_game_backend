# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.common_tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = 30

  tags = var.common_tags
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name_prefix}-task"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory

  container_definitions = jsonencode([
    {
      name  = "${var.name_prefix}-container"
      image = "${var.ecr_repository_url}:latest"
      
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
        }
      ]

      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "prod"
        },
        {
          name  = "MYSQL_HOST"
          value = var.db_address
        },
        {
          name  = "MYSQL_PORT"
          value = "3306"
        },
        {
          name  = "MYSQL_DB"
          value = "game_db"
        },
        {
          name  = "MYSQL_USER"
          value = var.db_username
        },
        {
          name  = "MYSQL_PASS"
          value = var.db_password
        },
        {
          name  = "SES_USERNAME"
          value = var.ses_username
        },
        {
          name  = "SES_PASSWORD"
          value = var.ses_password
        },
        {
          name  = "SES_FROM_EMAIL"
          value = var.ses_verified_email
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = var.common_tags
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [var.ecs_tasks_sg_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${var.name_prefix}-container"
    container_port   = var.app_port
  }

  tags = var.common_tags
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = var.app_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = var.common_tags
}

# Auto Scaling Policy
resource "aws_appautoscaling_policy" "ecs_policy_up" {
  name               = "${var.name_prefix}-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ecs cpu utilization"
  alarm_actions       = []

  dimensions = {
    ServiceName = aws_ecs_service.main.name
    ClusterName = aws_ecs_cluster.main.name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.name_prefix}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ecs memory utilization"
  alarm_actions       = []

  dimensions = {
    ServiceName = aws_ecs_service.main.name
    ClusterName = aws_ecs_cluster.main.name
  }

  tags = var.common_tags
}
