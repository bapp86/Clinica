data "aws_availability_zones" "available" {}

# Obtener LabRole existente (Permitido)
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# --- RED (VPC) ---
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.0"

  name = "etnet${var.iniciales}"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = var.tags
}

# --- EKS CLUSTER (Nativo) ---
resource "aws_eks_cluster" "main" {
  name     = "etcluster${var.iniciales}"
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }

  tags = var.tags
}

# --- EKS NODE GROUP (Nativo) ---
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "nodes-sanavi"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 3
    max_size     = 6
    min_size     = 2
  }

  instance_types = ["t3.small"]

  # Asegura que el cluster exista antes de crear nodos
  depends_on = [
    aws_eks_cluster.main
  ]

  tags = var.tags
}

# --- SERVERLESS (LAMBDA & API GW) ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "backend" {
  filename      = "lambda_function.zip"
  function_name = "etfxn${var.iniciales}-pacientes"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  environment {
    variables = { ENV = "PROD" }
  }
}

resource "aws_apigatewayv2_api" "api" {
  name          = "sana-vi-api-${var.iniciales}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.backend.invoke_arn
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /pacientes"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
