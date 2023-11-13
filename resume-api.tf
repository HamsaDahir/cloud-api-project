terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
# create s3 bucket

resource "aws_s3_bucket" "my-resume-api" {
  bucket = "my-resume-api"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_object" "file_upload" {
  bucket = "my-resume-api"
  key    = "Resume-json"
  source = "RESUME-JSON.json"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  
}

# This IAM role and policy allows your Lambda function to create.


resource "aws_iam_policy" "aws_iam_policy_for_lambda" {

  name        = "aws_iam_policy_for_serverless_lambda"
  path        = "/"
  description = "AWS IAM Policy for managing the serverless lambda function"
  policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Action : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource : "arn:aws:logs:*:*:*",
          Effect : "Allow"
        },
        {
          Effect : "Allow"
          Action : [
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Resource = [
            "arn:aws:s3:::serverless-resume-bucket",
            "arn:aws:s3:::serverless-resume-bucket/*"
          ]
        },
      ]
  })
}

resource "aws_iam_role" "iam_role_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "lambda.amazonaws.com"
                ]
            }
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment" {
  policy_arn = aws_iam_policy.aws_iam_policy_for_lambda.arn
  role = aws_iam_role.iam_role_for_lambda.name

}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

# created lambda funtion

resource "aws_lambda_function" "lambda_function" {
  function_name    = "fetch_s3_bucket"
  filename         = data.archive_file.zip_the_python_code.output_path
  source_code_hash = data.archive_file.zip_the_python_code.output_base64sha256
  handler          = "lambda.lambda_handler"
  role             = aws_iam_role.iam_role_for_lambda.arn
  runtime          = "python3.7"
  
}
