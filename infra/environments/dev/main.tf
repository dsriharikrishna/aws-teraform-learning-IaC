resource "random_string" "s3_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ==============================================================================
# Service 1: Reusable S3 Media Bucket
# ==============================================================================
module "media_bucket" {
  source = "../../modules/s3"

  bucket_name         = "${var.project_name}-${var.environment}-media-${random_string.s3_suffix.result}"
  enable_versioning   = true
  block_public_access = true

  tags = {
    Module  = "Storage"
    Purpose = "Media"
  }
}

# ==============================================================================
# Service 2: Reusable VPC Module
# ==============================================================================
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = false # Set to true when private containers need outbound internet

  tags = {
    Module = "Networking"
  }
}

# ==============================================================================
# Service 3: Reusable Security Groups Module
# ==============================================================================
module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id

  tags = {
    Module = "Security"
  }
}

# ==============================================================================
# Service 4: Reusable EC2 Web Server Module
# ==============================================================================
module "ec2_server" {
  source = "../../modules/ec2"

  project_name           = var.project_name
  environment            = var.environment
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.security_groups.ec2_security_group_id]
  associate_public_ip    = true

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from AWS EC2 provisioned by Terraform!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Module = "Compute"
    Role   = "WebServer"
  }
}

# ==============================================================================
# Service 5: Reusable ECR Container Registry
# ==============================================================================
module "ecr" {
  source = "../../modules/ecr"

  repository_name      = "${var.project_name}-${var.environment}-repo"
  environment          = var.environment
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  max_image_count      = 10

  tags = {
    Module = "Containers"
  }
}

# ==============================================================================
# Service 6: Reusable IAM Roles for ECS
# ==============================================================================
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment

  tags = {
    Module = "Identity"
  }
}

# ==============================================================================
# Service 7: Reusable CloudWatch Monitoring
# ==============================================================================
module "monitoring" {
  source = "../../modules/monitoring"

  project_name      = var.project_name
  environment       = var.environment
  retention_in_days = 7

  tags = {
    Module = "Monitoring"
  }
}

# ==============================================================================
# Service 8: Reusable Application Load Balancer (ALB)
# ==============================================================================
module "alb" {
  source = "../../modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  target_port           = 80
  health_check_path     = "/"

  tags = {
    Module = "Routing"
  }
}

# ==============================================================================
# Service 9: Reusable RDS Database (PostgreSQL)
# ==============================================================================
module "rds" {
  source = "../../modules/rds"

  project_name         = var.project_name
  environment          = var.environment
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = "db.t4g.micro"
  db_name              = "appdb"
  db_username          = "dbadmin"
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_security_group_id = module.security_groups.db_security_group_id
  multi_az             = false # Cost saving for dev
  skip_final_snapshot  = true  # Fast cleanup for dev

  tags = {
    Module = "Database"
  }
}

# ==============================================================================
# Service 10: Reusable ECS Fargate Cluster & Service
# ==============================================================================
module "ecs" {
  source = "../../modules/ecs"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  app_security_group_id = module.security_groups.app_security_group_id
  target_group_arn      = module.alb.target_group_arn
  container_image       = "public.ecr.aws/nginx/nginx:latest"
  container_port        = 80
  cpu                   = 256
  memory                = 512
  desired_count         = 1
  execution_role_arn    = module.iam.ecs_execution_role_arn
  task_role_arn         = module.iam.ecs_task_role_arn
  log_group_name        = module.monitoring.log_group_name
  aws_region            = var.aws_region

  tags = {
    Module = "Compute"
    Type   = "Fargate"
  }
}
