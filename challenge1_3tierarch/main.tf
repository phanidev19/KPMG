################################################
# AWS Provider
################################################
provider "aws" {
  region = var.aws_region
}

################################################
# Network layer
################################################
module "vpc" {

  source = "terraform-aws-modules/vpc/aws"

  name            = "kpmg-challenge-vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "kpmg-challenge"
  }
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "*public*"
  }
  depends_on = [module.vpc]
}

data "aws_subnet" "public_subnets" {
  for_each = data.aws_subnet_ids.public_subnets.ids
  id       = each.value
  depends_on = [module.vpc]
}


data "aws_subnet_ids" "private_subnets" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "*private*"
  }
  depends_on = [module.vpc]
}

data "aws_subnet" "private_subnets" {
  for_each = data.aws_subnet_ids.private_subnets.ids
  id       = each.value
  depends_on = [module.vpc]
}


################################################
# EC2 instances
################################################
resource "aws_instance" "pub-ec2" {
  count         = var.ec2_count
  ami           = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [var.sg_id]
  subnet_id = [for s in data.aws_subnet.public_subnets : s.id][0]
  key_name = var.ssh_key
  associate_public_ip_address = true


  tags = {
    Name = "kpmg-challenge-ec2-public"

  }
}


resource "aws_instance" "pvt-ec2" {
  count         = var.ec2_count
  ami           = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [var.sg_id]
  subnet_id = [for s in data.aws_subnet.private_subnets : s.id][0]
  key_name = var.ssh_key
  associate_public_ip_address = false


  tags = {
    Name = "kpmg-challenge-ec2-pvt"

  }
}

################################################
# Application Loadbalancer - Public
################################################
resource "aws_lb" "kpmg-challenge-pub-alb" {
  name               = "kpmg-challenge-pub-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_id]
  subnets            = [[for s in data.aws_subnet.public_subnets : s.id][1]]
}

# Target Group for Application Load Balancer
resource "aws_lb_target_group" "kpmg-challenge-pub-tg" {
  name     = "kpmg-challenge-pub-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${module.vpc.id}"
}
resource "aws_lb_target_group_attachment" "kpmg-challenge-pub-tg-attachment" {
  target_group_arn = "${aws_lb_target_group.kpmg-challenge-pub-tg.arn}"
  target_id        = "${aws_instance.pub-ec2.id}"
  port             = 80
}
resource "aws_lb_listener" "kpmg-web-alb-listener" {
  load_balancer_arn = "${kpmg-challenge-pub-alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.kpmg-challenge-pub-tg.arn}"
  }
}


################################################
# Application Loadbalancer - Internal
################################################
resource "aws_lb" "kpmg-challenge-pvt-alb" {
  name               = "kpmg-challenge-pvt-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.sg_id]
  subnets            = [[for s in data.aws_subnet.private_subnets : s.id][1]]



}


# Target Group for Application Load Balancer
resource "aws_lb_target_group" "kpmg-challenge-pvt-tg" {
  name     = "kpmg-challenge-pvt-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${module.vpc.id}"
}
resource "aws_lb_target_group_attachment" "kpmg-challenge-pvt-tg-attachment" {
  target_group_arn = "${aws_lb_target_group.kpmg-challenge-pvt-tg.arn}"
  target_id        = "${aws_instance.pvt-ec2.id}"
  port             = 80
}
resource "aws_lb_listener" "kpmg-web-alb-listener" {
  load_balancer_arn = "${kpmg-challenge-pvt-alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.kpmg-challenge-pvt-tg.arn}"
  }
}


################################################
#Auto Scaling
################################################

resource"aws_launch_configuration" "launch-config" {
  name = var.env
  image_id = var.ami_id
  instance_type = var.instance_type
  security_groups = [var.sg_id]
}

resource "aws_autoscaling_group" "worker" {
    name = "${aws_launch_configuration.launch-config.name}-asg"
    min_size             = 2
    desired_capacity     = 2
    max_size             = 4
    health_check_type    = "EC2"

    launch_configuration = "${aws_launch_configuration.launch-config.name}"
    vpc_zone_identifier  = [[for s in data.aws_subnet.private_subnets : s.id][1]]
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.worker.id
  alb_target_group_arn   = aws_lb_target_group.kpmg-tg.arn
}

resource "aws_lb" "kpmg-alb" {
  name               = "kpmg-dev-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.sg_id]
  subnets            = [[for s in data.aws_subnet.private_subnets : s.id][1]]

  enable_deletion_protection = false

  tags = {
    Environment = "demo"
  }
}


resource "aws_lb_target_group" "kpmg-tg" {
  name     = "kpmg-dev-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.kpmg-vpc.id}"
}

resource "aws_lb_listener" "kpmg-alb-listener" {
  load_balancer_arn = "${aws_lb.kpmg-alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.kpmg-tg.arn}"
  }
}



################################################
#Create RDS
################################################

resource "aws_db_subnet_group" "pvt_subnet_grp" {
  name       = "main"
  subnet_ids = [[for s in data.aws_subnet.private_subnets : s.id][1]]

  tags = {
    Name = "kpm-challenge-rds-grp"
  }
}

resource "aws_rds_cluster_instance" "kpmg_challenge_rds" {
  count                      = "${var.no_of_db_instances}"
  publicly_accessible        = false
  identifier                 =  "kpmg-challenge-rds"
  cluster_identifier         = "${aws_rds_cluster.rds_kpmg_cluster.id}"
  instance_class             = "${var.rds_instance_type}"
  engine                     = "${aws_rds_cluster.rds_kpmg_cluster.engine}"
  engine_version             = "${aws_rds_cluster.rds_kpmg_cluster.engine_version}"


}
resource "aws_rds_cluster" "rds_kpmg_cluster" {
  cluster_identifier         = var.env
  engine                     = "${var.engine}"
  engine_version             = "${var.db_engine_version}"
  port                       = "${var.db_port}"
  master_username            = "${var.db_username}"
  master_password            = "${var.db_password}"
  deletion_protection        = false
  db_subnet_group_name       = "${aws_db_subnet_group.default.id}"
  vpc_security_group_ids     = [aws_security_group.kpmg-sg-pub.id]
  skip_final_snapshot        = true
  storage_encrypted          = true

}