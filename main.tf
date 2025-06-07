terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.95.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

#--------------------------------------------------------------------------------------------------
# Create a VPC
#--------------------------------------------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "chatbot-vpc"
  }
}

#--------------------------------------------------------------------------------------------------
# Create subnets
#--------------------------------------------------------------------------------------------------

resource "aws_subnet" "private-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-1"
  }
}

resource "aws_subnet" "private-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-2"
  }
}

resource "aws_subnet" "public-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1d"
  tags = {
    Name = "public-2"
  }
}

#--------------------------------------------------------------------------------------------------
# Create an internet gateway
#--------------------------------------------------------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "chatbot-igw"
  }
}

#--------------------------------------------------------------------------------------------------
# Create a route table for public subnets
#--------------------------------------------------------------------------------------------------

resource "aws_route_table" "rt-pub" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "rt-pub"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

#--------------------------------------------------------------------------------------------------
# Attach the route table to the public subnets
#--------------------------------------------------------------------------------------------------

resource "aws_route_table_association" "rt-pub-1" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.rt-pub.id
}

resource "aws_route_table_association" "rt-pub-2" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.rt-pub.id
}

#--------------------------------------------------------------------------------------------------
# Create an EIP for NAT gateway
#--------------------------------------------------------------------------------------------------

resource "aws_eip" "nat-private-1" {
  domain = "vpc"
  tags = {
    Name = "nat-private-1"
  }
}

#--------------------------------------------------------------------------------------------------
# Create a NAT gateway for private subnets
#--------------------------------------------------------------------------------------------------

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat-private-1.id
  subnet_id     = aws_subnet.public-1.id
  tags = {
    Name = "chatbot-nat-gateway"
  }
}

#--------------------------------------------------------------------------------------------------
# Create a route table for NAT gateway
#--------------------------------------------------------------------------------------------------

resource "aws_route_table" "rt-nat" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "rt-nat"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

#--------------------------------------------------------------------------------------------------
# Associate the NAT gateway with private subnets
#--------------------------------------------------------------------------------------------------

resource "aws_route_table_association" "rt-nat-1" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.rt-nat.id
}

resource "aws_route_table_association" "rt-nat-2" {
  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.rt-nat.id
}

#--------------------------------------------------------------------------------------------------
# Create security groups
#--------------------------------------------------------------------------------------------------

resource "aws_security_group" "ec2-sg" {
  name        = "ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_security_group" "cluster-sg" {
  name        = "cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cluster-sg"
  }
}

resource "aws_security_group" "node-sg" {
  name        = "node-sg"
  description = "Security group for EKS nodes"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "node-sg"
  }
}

#--------------------------------------------------------------------------------------------------
# Create an EC2 instance
#--------------------------------------------------------------------------------------------------

resource "aws_instance" "ec2" {
  ami                         = "ami-0e449927258d45bc4" # Amazon Linux 2 in us-east-1
  instance_type               = "t3a.medium"
  subnet_id                   = aws_subnet.public-1.id
  vpc_security_group_ids      = [aws_security_group.ec2-sg.id]
  key_name                    = "us-east"
  associate_public_ip_address = true

  tags = {
    Name = "chatbot-ec2"
  }
}

#--------------------------------------------------------------------------------------------------
# Create a DynamoDB table
#--------------------------------------------------------------------------------------------------

resource "aws_dynamodb_table" "db-table" {
  name             = "chat-bot"
  hash_key         = "sessionId"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "sessionId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "sender"
    type = "S"
  }

  attribute {
    name = "message"
    type = "S"
  }

  global_secondary_index {
    name               = "TimestampIndex"
    hash_key           = "sessionId"
    range_key          = "timestamp"
    projection_type    = "ALL"
    write_capacity     = 5
    read_capacity      = 5
  }

  global_secondary_index {
    name               = "SenderIndex"
    hash_key           = "sender"
    range_key          = "timestamp"
    projection_type    = "ALL"
    write_capacity     = 5
    read_capacity      = 5
  }

   global_secondary_index {
    name            = "MessageIndex"
    hash_key        = "message"     
      range_key       = "timestamp"   
    projection_type = "INCLUDE"     
    non_key_attributes = ["sessionId", "sender"] 
  }

  tags = {
    Name = "chatbot-dynamodb"
  }
}

#--------------------------------------------------------------------------------------------------
# Create an S3 Bucket
#--------------------------------------------------------------------------------------------------

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "private-s3" {
  bucket = "private-tf-bucket-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "chatbot-private-bucket"
  }
}

#--------------------------------------------------------------------------------------------------
# Create IAM roles
#--------------------------------------------------------------------------------------------------

resource "aws_iam_role" "eks-role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks-attach" {
  role       = aws_iam_role.eks-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks-node" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "eks-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "node-attach" {
  role       = aws_iam_role.eks-node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node1-attach" {
  role       = aws_iam_role.eks-node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node2-attach" {
  role       = aws_iam_role.eks-node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role" "alb-role" {
  name = "alb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "elasticloadbalancing.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "alb-role"
  }
}

resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Permissions for AWS Load Balancer Controller"
  policy      = file("C:/Users/Piyush/Desktop/aviral-project/chatbot-cicd/load-balancer-controller-policy.json")
}

#--------------------------------------------------------------------------------------------------
# Create EKS cluster
#--------------------------------------------------------------------------------------------------

resource "aws_eks_cluster" "eks" {
  name     = "chatbot-k8s"
  role_arn = aws_iam_role.eks-role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = [
      aws_subnet.private-1.id,
      aws_subnet.private-2.id,
    ]
    security_group_ids = [aws_security_group.cluster-sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-attach
  ]
}

#--------------------------------------------------------------------------------------------------
# Create EKS Node Group
#--------------------------------------------------------------------------------------------------

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "chatbot-nodes"
  node_role_arn   = aws_iam_role.eks-node.arn
  subnet_ids      = [aws_subnet.private-1.id, aws_subnet.private-2.id]

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }

  instance_types = ["t3a.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.node-attach,
    aws_iam_role_policy_attachment.node1-attach,
    aws_iam_role_policy_attachment.node2-attach
  ]
}

#--------------------------------------------------------------------------------------------------
# Create security group for load balancer
#--------------------------------------------------------------------------------------------------

resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

#--------------------------------------------------------------------------------------------------
# Create a load balancer
#--------------------------------------------------------------------------------------------------

resource "aws_lb" "eks-lb" {
  name               = "chatbot-eks-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.public-1.id, aws_subnet.public-2.id]

  enable_deletion_protection = false

  tags = {
    Name = "chatbot-eks-lb"
  }
}

#--------------------------------------------------------------------------------------------------
# Create a target group for load balancer
#--------------------------------------------------------------------------------------------------

resource "aws_lb_target_group" "alb-tg" {
  name        = "chatbot-tg-alb"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "chatbot-tg-alb"
  }
}

#--------------------------------------------------------------------------------------------------
# Create a listener for load balancer
#--------------------------------------------------------------------------------------------------

resource "aws_lb_listener" "http_only" {
  load_balancer_arn = aws_lb.eks-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
}

#--------------------------------------------------------------------------------------------------
# Create an ECR repository
#--------------------------------------------------------------------------------------------------

resource "aws_ecr_repository" "ecr" {
  name                 = "chatbot-docker-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "chatbot-ecr"
  }
}

#--------------------------------------------------------------------------------------------------
# Create an auto scaling group
#--------------------------------------------------------------------------------------------------

resource "aws_launch_template" "auto-scaling" {
  name_prefix   = "chatbot-asg"
  image_id      = "ami-0e449927258d45bc4"
  instance_type = "t3a.micro"
}

resource "aws_autoscaling_group" "asg" {
  name_prefix          = "chatbot-asg-"
  vpc_zone_identifier  = [aws_subnet.private-1.id, aws_subnet.private-2.id]
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  health_check_type    = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.auto-scaling.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "chatbot-asg-instance"
    propagate_at_launch = true
  }
}

#--------------------------------------------------------------------------------------------------
# Create a CloudWatch alarm
#--------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "chatbot_ec2_cpu_alarm" {
  alarm_name          = "chatbot-prod-ec2-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Triggers when EC2 CPU exceeds 75% for 15 minutes. Check chatbot service load and consider scaling."
  treat_missing_data  = "ignore"

  dimensions = {
    InstanceId = aws_instance.ec2.id
  }
}