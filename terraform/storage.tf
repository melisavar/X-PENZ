# Storage- dynamodb, s3 frontend, s3 receipts

#DynamoDB 
resource "aws_dynamodb_table" "expenses" {
  name         = "expense-table"
  billing_mode = "PAY_PER_REQUEST"   # serverless, pay as you go
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = { Project = var.project_name }
}

# S3 bucket for static frontend

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${random_id.suffix.hex}"
  tags   = { Project = var.project_name }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#S3 receipts - accessed via pre-signed URLs
resource "aws_s3_bucket" "receipts" {
  bucket = "${var.project_name}-receipts-${random_id.suffix.hex}"
  tags   = { Project = var.project_name }
}

resource "aws_s3_bucket_public_access_block" "receipts" {
  bucket                  = aws_s3_bucket.receipts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Browser PUTs need CORS on the receipts bucket
resource "aws_s3_bucket_cors_configuration" "receipts" {
  bucket = aws_s3_bucket.receipts.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

# S3 event → trigger imageExtractor Lambda on every upload
resource "aws_s3_bucket_notification" "receipts_trigger" {
  bucket = aws_s3_bucket.receipts.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_extractor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_trigger]
}
