output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.app.private_ip
}

output "scheduler_lambda_arn" {
  description = "ARN of the EC2 start/stop scheduler Lambda function"
  value       = aws_lambda_function.scheduler.arn
}
