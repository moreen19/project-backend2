provider "aws" {
  region = "us-east-1"
}

# Import existing DynamoDB table
resource "aws_dynamodb_table" "visitor_count_table" {
  name         = "VisitorCountTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Reference existing IAM role (visitoCcounterFunction-role-hyousyxy)
resource "aws_iam_role" "lambda_exec_role" {
  name = "visitoCcounterFunction-role-hyousyxy"
  path = "/service-role/"  

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Import existing Lambda function
resource "aws_lambda_function" "visitor_counter" {
  function_name = "visitoCcounterFunction"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  filename      = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  lifecycle {
    prevent_destroy = true
  }
}

# Import existing API Gateway
resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "VisitorCounterAPI"
  protocol_type = "HTTP"

  lifecycle {
    prevent_destroy = true
  }
}

# Reference default stage (no need to create a new one)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.visitor_api.id
  name        = "$default"
  auto_deploy = true

  lifecycle {
    prevent_destroy = true
  }
}

# Import existing integration and route
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.visitor_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.visitor_counter.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_apigatewayv2_route" "visitor_route" {
  api_id    = aws_apigatewayv2_api.visitor_api.id
  route_key = "GET /visitors"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "VisitorCounterAPI"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type"]
    allow_methods     = ["GET", "POST", "OPTIONS"]
    allow_origins     = ["*"]
    expose_headers    = []
    max_age           = 0
  }
}


resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "54c7ad3b-3fbe-5ab9-b621-4edc92129999"
  action        = "lambda:InvokeFunction"
  function_name =  aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-east-1:599704543248:4szhrfmjee*/*/visitors"

  lifecycle {
    prevent_destroy = true
  }

}
