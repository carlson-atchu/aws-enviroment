output "bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "bucket_arn" {
  description = "ARN of the state bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the state bucket"
  value       = aws_kms_key.terraform_state.arn
}
