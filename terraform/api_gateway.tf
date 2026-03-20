#REST API, routes, CORS

# REST API
resource "aws_api_gateway_rest_api" "xpenz" {
  name        = "${var.project_name}-api"
  description = "X-Penz expense tracker API"
}

#Reusable CORS response headers
locals {
  cors_headers = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  cors_response_params = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# /manual-extract  (POST)
resource "aws_api_gateway_resource" "manual_extract" {
  rest_api_id = aws_api_gateway_rest_api.xpenz.id
  parent_id   = aws_api_gateway_rest_api.xpenz.root_resource_id
  path_part   = "manual-extract"
}
resource "aws_api_gateway_method" "manual_post" {
  rest_api_id   = aws_api_gateway_rest_api.xpenz.id
  resource_id   = aws_api_gateway_resource.manual_extract.id
  http_method   = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "manual_post" {
  rest_api_id             = aws_api_gateway_rest_api.xpenz.id
  resource_id             = aws_api_gateway_resource.manual_extract.id
  http_method             = aws_api_gateway_method.manual_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.manual_extractor.invoke_arn
}
resource "aws_api_gateway_method" "manual_options" {
  rest_api_id   = aws_api_gateway_rest_api.xpenz.id
  resource_id   = aws_api_gateway_resource.manual_extract.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "manual_options" {
  rest_api_id = aws_api_gateway_rest_api.xpenz.id
  resource_id = aws_api_gateway_resource.manual_extract.id
  http_method = aws_api_gateway_method.manual_options.http_method
  type        = "MOCK"
  request_templates = { "application/json" = "{\"statusCode\": 200}" }
}
resource "aws_api_gateway_method_response" "manual_options_200" {
  rest_api_id         = aws_api_gateway_rest_api.xpenz.id
  resource_id         = aws_api_gateway_resource.manual_extract.id
  http_method         = aws_api_gateway_method.manual_options.http_method
  status_code         = "200"
  response_parameters = local.cors_response_params
}
resource "aws_api_gateway_integration_response" "manual_options" {
  rest_api_id         = aws_api_gateway_rest_api.xpenz.id
  resource_id         = aws_api_gateway_resource.manual_extract.id
  http_method         = aws_api_gateway_method.manual_options.http_method
  status_code         = aws_api_gateway_method_response.manual_options_200.status_code
  response_parameters = local.cors_headers
  depends_on          = [aws_api_gateway_integration.manual_options]
}

# /voice-extract  (POST)
resource "aws_api_gateway_resource" "voice_extract" {
  rest_api_id = aws_api_gateway_rest_api.xpenz.id
  parent_id   = aws_api_gateway_rest_api.xpenz.root_resource_id
  path_part   = "voice-extract"
}
resource "aws_api_gateway_method" "voice_post" {
  rest_api_id   = aws_api_gateway_rest_api.xpenz.id
  resource_id   = aws_api_gateway_resource.voice_extract.id
  http_method   = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "voice_post" {
  rest_api_id             = aws_api_gateway_rest_api.xpenz.id
  resource_id             = aws_api_gateway_resource.voice_extract.id
  http_method             = aws_api_gateway_method.voice_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.voice_extractor.invoke_arn
}
resource "aws_api_gateway_method" "voice_options" {
  rest_api_id   = aws_api_gateway_rest_api.xpenz.id
  resource_id   = aws_api_gateway_resource.voice_extract.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "voice_options" {
  rest_api_id = aws_api_gateway_rest_api.xpenz.id
  resource_id = aws_api_gateway_resource.voice_extract.id
  http_method = aws_api_gateway_method.voice_options.http_method
  type        = "MOCK"
  request_templates = { "application/json" = "{\"statusCode\": 200}" }
}
resource "aws_api_gateway_method_response" "voice_options_200" {
  rest_api_id         = aws_api_gateway_rest_api.xpenz.id
  resource_id         = aws_api_gateway_resource.voice_extract.id
  http_method         = aws_api_gateway_method.voice_options.http_method
  status_code         = "200"
  response_parameters = local.cors_response_params
}
resource "aws_api_gateway_integration_response" "voice_options" {
  rest_api_id         = aws_api_gateway_rest_api.xpenz.id
  resource_id         = aws_api_gateway_resource.voice_extract.id
  http_method         = aws_api_gateway_method.voice_options.http_method
  status_code         = aws_api_gateway_method_response.voice_options_200.status_code
  response_parameters = local.cors_headers
  depends_on          = [aws_api_gateway_integration.voice_options]
}

# /expenses  (GET)
resource "aws_api_gateway_resource" "expenses" {
  rest_api_id = aws_api_gateway_rest_api.xpenz.id
  parent_id   = aws_api_gateway_rest_api.xpenz.root_resource_id
  path_part   = "expenses"
}
resource "aws_api_gateway_method" "expenses_get" {
  rest_api_id   = aws_api_gateway_rest_api.xpenz.id
  resource_id   = aws_api_gateway_resource.expenses.id
  http_method   = "GET"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "expenses_get" {
  rest_api_id             = aws_api_gateway_rest_api.xpenz.id
  resource_id             = aws_api_gateway_resource.expenses.id
  http_method             = aws_api_gateway_method.expenses_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_expenses.invoke_arn
}
resource "aws_api_gateway_method" "expenses_options" {
  rest_api_id   = aws_api_gateway_rest_api.xpenz.id
  resource_id   = aws_api_gateway_resource.expenses.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "expenses_options" {
  rest_api_id = aws_api_gateway_rest_api.xpenz.id
  resource_id = aws_api_gateway_resource.expenses.id
  http_method = aws_api_gateway_method.expenses_options.http_method
  type        = "MOCK"
  request_templates = { "application/json" = "{\"statusCode\": 200}" }
}
resource "aws_api_gateway_method_response" "expenses_options_200" {
  rest_api_id         = aws_api_gateway_rest_api.xpenz.id
  resource_id         = aws_api_gateway_resource.expenses.id
  http_method         = aws_api_gateway_method.expenses_options.http_method
  status_code         = "200"
  response_parameters = local.cors_response_params
}
resource "aws_api_gateway_integration_response" "expenses_options" {
  rest_api_id         = aws_api_gateway_rest_api.xpenz.id
  resource_id         = aws_api_gateway_resource.expenses.id
  http_method         = aws_api_gateway_method.expenses_options.http_method
  status_code         = aws_api_gateway_method_response.expenses_options_200.status_code
  response_parameters = local.cors_headers
  depends_on          = [aws_api_gateway_integration.expenses_options]
}

# /generate-URL  (GET)
resource "aws_api_gateway_resource" "generate_url" {
  rest_api_id = aws_api_gateway_rest_api.xpenz.id
  parent_id   = aws_api_gateway_rest_api.xpenz.root_resource_id
  path_part   = "generate-URL"
}
resource "aws_api_gateway_method" "generate_url_get" {
  rest_api_id   = aws_api_gateway_rest_api.xpenz.id
  resource_id   = aws_api_gateway_resource.generate_url.id
  http_method   = "GET"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "generate_url_get" {
  rest_api_id             = aws_api_gateway_rest_api.xpenz.id
  resource_id             = aws_api_gateway_resource.generate_url.id
  http_method             = aws_api_gateway_method.generate_url_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.generate_url.invoke_arn
}
resource "aws_api_gateway_method" "generate_url_options" {
  rest_api_id   = aws_api_gateway_rest_api.xpenz.id
  resource_id   = aws_api_gateway_resource.generate_url.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "generate_url_options" {
  rest_api_id = aws_api_gateway_rest_api.xpenz.id
  resource_id = aws_api_gateway_resource.generate_url.id
  http_method = aws_api_gateway_method.generate_url_options.http_method
  type        = "MOCK"
  request_templates = { "application/json" = "{\"statusCode\": 200}" }
}
resource "aws_api_gateway_method_response" "generate_url_options_200" {
  rest_api_id         = aws_api_gateway_rest_api.xpenz.id
  resource_id         = aws_api_gateway_resource.generate_url.id
  http_method         = aws_api_gateway_method.generate_url_options.http_method
  status_code         = "200"
  response_parameters = local.cors_response_params
}
resource "aws_api_gateway_integration_response" "generate_url_options" {
  rest_api_id         = aws_api_gateway_rest_api.xpenz.id
  resource_id         = aws_api_gateway_resource.generate_url.id
  http_method         = aws_api_gateway_method.generate_url_options.http_method
  status_code         = aws_api_gateway_method_response.generate_url_options_200.status_code
  response_parameters = local.cors_headers
  depends_on          = [aws_api_gateway_integration.generate_url_options]
}


# Deploy to "prod" stage
resource "aws_api_gateway_deployment" "xpenz" {
  rest_api_id = aws_api_gateway_rest_api.xpenz.id

  # Re-deploy whenever any method or integration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.manual_post,
      aws_api_gateway_integration.voice_post,
      aws_api_gateway_integration.expenses_get,
      aws_api_gateway_integration.generate_url_get,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.xpenz.id
  rest_api_id   = aws_api_gateway_rest_api.xpenz.id
  stage_name    = "prod"
}
