terraform { 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = "ap-south-1"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

# Get latest snapshot from production DB
data "aws_db_snapshot" "db_snapshot" {
  most_recent = true
  db_instance_identifier = "DB-NAME"
}
 
#copy snapshot production DB to Staging DB
resource "aws_db_snapshot_copy" "db_copy" {
  source_db_snapshot_identifier = data.aws_db_snapshot.db_snapshot.id
  target_db_snapshot_identifier = "${data.aws_db_snapshot.db_snapshot.id}-copy"
  destination_region            = "ap-southeast-1"
}

# Create new staging DB
resource "aws_db_instance" "db_copy" {
  engine               = "mysql"
  snapshot_identifier  = "${data.aws_db_snapshot.db_snapshot.id}"
  identifier           = "DB-NAME-copy"
  instance_class       = "db.t3.medium"
  db_subnet_group_name = "default-vpc-xxxxxxxx"
#   vpc_security_group_ids = ["sg-xxxxxxxx"]
  skip_final_snapshot = true
}

#get endpoint of new created staging db
output "rds_endpoint" {
  value = "${aws_db_instance.db_copy.endpoint}"
}

data "aws_route53_zone" "db_copy" {
  name = "example.com"
}

resource "aws_route53_record" "db_copy" {
  allow_overwrite = true
  name            = "www.example.com"
  type            = "CNAME"
  zone_id         = "xxxxxxxxxxxxxxxxxxx"
  alias {
    zone_id         = "xxxxxxxxxxxxxxxxxxxxxx"
    name            = "${aws_db_instance.db_copy.endpoint}"
    evaluate_target_health = true
  }
}

