# Define o provedor AWS e a região
provider "aws" {
  region = "us-east-1"
}

# Cria uma VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Cria uma subnet privada para o RDS (substitua a zona e o cidr_block conforme necessário)
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a" # Substitua pela zona desejada
  map_public_ip_on_launch = false
}

resource "aws_subnet" "my_subnet_us-east-1b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"  # Escolha um CIDR diferente
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
}


# Cria um subnet group para o RDS
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.my_subnet.id, aws_subnet.my_subnet_us-east-1b.id]
}

# Cria uma instância RDS (PostgreSQL)
resource "aws_db_instance" "db_postgre_instance" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = "db.t3.micro"
  db_name              = "db_test"
  username             = "master"
  password             = "adminpass"
  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
}

# IAM Configuração
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Cria uma função Lambda
resource "aws_lambda_function" "my_lambda_function" {
  function_name = "test-lambda"
  filename     = "../test-lambda.zip" # Substitua pelo caminho para seu código Lambda
  handler      = "index.handler"
  runtime      = "nodejs14.x"
  source_code_hash = filebase64sha256("../test-lambda.zip")
  role        = aws_iam_role.lambda_execution_role.arn
  depends_on  = [aws_db_instance.db_postgre_instance]
}

# Cria uma regra de segurança para a função Lambda (permite o acesso ao RDS)
# resource "aws_security_group" "lambda_security_group" {
#   vpc_id = aws_vpc.my_vpc.id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   // Permita o tráfego na porta do banco de dados (5432) do RDS
#   ingress {
#     from_port   = 5432
#     to_port     = 5432
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.my_vpc.cidr_block]
#   }
# }

# Associa a regra de segurança à função Lambda
# resource "aws_lambda_function" "my_lambda_function" {
#   ...
#   vpc_config {
#     security_group_ids = [aws_security_group.lambda_security_group.id]
#     subnet_ids         = [aws_subnet.my_subnet.id]
#   }
# }

# Cria uma regra de segurança para o RDS (permitindo acesso a partir da função Lambda)
# resource "aws_security_group" "rds_security_group" {
#   vpc_id = aws_vpc.my_vpc.id

#   egres {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

  // Permita o tráfego na porta 5432 da função Lambda
#   ingress {
#     from_port       = 5432
#     to_port         = 5432
#     protocol        = "tcp"
#     security_groups = [aws_security_group.lambda_security_group.id]
#   }
# }

# Associa a regra de segurança ao RDS
# resource "aws_db_instance" "my_db_instance" {
#   ...
#   vpc_security_group_ids = [aws_security_group.rds_security_group.id]
# }
