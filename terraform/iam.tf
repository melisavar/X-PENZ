# IAM roles, permissions
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "DynamoDB"
        Effect = "Allow"
        Action = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Scan", "dynamodb:Query"]
        Resource = aws_dynamodb_table.expenses.arn
      },
      {
        Sid      = "S3Receipts"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.receipts.arn}/*"
      },
      {
        Sid      = "S3PresignedURL"
        Effect   = "Allow"
        Action   = ["s3:GeneratePresignedUrl"]
        Resource = "${aws_s3_bucket.receipts.arn}/*"
      },
      {
        Sid      = "Textract"
        Effect   = "Allow"
        Action   = ["textract:DetectDocumentText"]
        Resource = "*"
      }
    ]
  })
}
