# Lambda functions and permissions
# Zip Lambda source files for deployment

locals {
  lambda_zips_dir = "${path.module}/.lambda_zips"
  python_runtime  = "python3.13"
  node_runtime    = "nodejs20.x"
  default_timeout = 30
}

data "archive_file" "manual_extractor" {
  type        = "zip"
  source_file = "${path.module}/../backend/manualExtractor.py"
  output_path = "${local.lambda_zips_dir}/manualExtractor.zip"
}

data "archive_file" "voice_extractor" {
  type        = "zip"
  source_file = "${path.module}/../backend/voiceExtractor.py"
  output_path = "${local.lambda_zips_dir}/voiceExtractor.zip"
}

data "archive_file" "image_extractor" {
  type        = "zip"
  source_file = "${path.module}/../backend/imageExtractor.py"
  output_path = "${local.lambda_zips_dir}/imageExtractor.zip"
}

data "archive_file" "get_expenses" {
  type        = "zip"
  source_file = "${path.module}/../backend/getExpenses.js"
  output_path = "${local.lambda_zips_dir}/getExpenses.zip"
}

data "archive_file" "generate_url" {
  type        = "zip"
  source_file = "${path.module}/../backend/generateURL.py"
  output_path = "${local.lambda_zips_dir}/generateURL.zip"
}

# Lambda Functions
resource "aws_lambda_function" "manual_extractor" {
  function_name    = "${var.project_name}-manualExtractor"
  filename         = data.archive_file.manual_extractor.output_path
  source_code_hash = data.archive_file.manual_extractor.output_base64sha256
  handler          = "manualExtractor.lambda_handler"
  runtime          = local.python_runtime
  role             = aws_iam_role.lambda_exec.arn
  timeout          = local.default_timeout

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.expenses.name }
  }
}

resource "aws_lambda_function" "voice_extractor" {
  function_name    = "${var.project_name}-voiceExtractor"
  filename         = data.archive_file.voice_extractor.output_path
  source_code_hash = data.archive_file.voice_extractor.output_base64sha256
  handler          = "voiceExtractor.lambda_handler"
  runtime          = local.python_runtime
  role             = aws_iam_role.lambda_exec.arn
  timeout          = local.default_timeout

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.expenses.name }
  }
}

resource "aws_lambda_function" "image_extractor" {
  function_name    = "${var.project_name}-imageExtractor"
  filename         = data.archive_file.image_extractor.output_path
  source_code_hash = data.archive_file.image_extractor.output_base64sha256
  handler          = "imageExtractor.lambda_handler"
  runtime          = local.python_runtime
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 60  

  environment {
    variables = {
      TABLE_NAME      = aws_dynamodb_table.expenses.name
      RECEIPTS_BUCKET = aws_s3_bucket.receipts.bucket
    }
  }
}

resource "aws_lambda_function" "get_expenses" {
  function_name    = "${var.project_name}-getExpenses"
  filename         = data.archive_file.get_expenses.output_path
  source_code_hash = data.archive_file.get_expenses.output_base64sha256
  handler          = "getExpenses.handler"
  runtime          = local.node_runtime   
  role             = aws_iam_role.lambda_exec.arn
  timeout          = local.default_timeout

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.expenses.name }
  }
}

resource "aws_lambda_function" "generate_url" {
  function_name    = "${var.project_name}-generateURL"
  filename         = data.archive_file.generate_url.output_path
  source_code_hash = data.archive_file.generate_url.output_base64sha256
  handler          = "generateURL.lambda_handler"
  runtime          = local.python_runtime
  role             = aws_iam_role.lambda_exec.arn
  timeout          = local.default_timeout

  environment {
    variables = { RECEIPTS_BUCKET = aws_s3_bucket.receipts.bucket }
  }
}

# Lambda Permissions

# Allow S3 receipts bucket to invoke imageExtractor
resource "aws_lambda_permission" "allow_s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_extractor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.receipts.arn
}

# Allow API Gateway to invoke each of the 4 API functions
resource "aws_lambda_permission" "apigw_manual" {
  statement_id  = "AllowAPIGWInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.manual_extractor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.xpenz.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_voice" {
  statement_id  = "AllowAPIGWInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.voice_extractor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.xpenz.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_get" {
  statement_id  = "AllowAPIGWInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_expenses.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.xpenz.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_url" {
  statement_id  = "AllowAPIGWInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.xpenz.execution_arn}/*/*"
}
