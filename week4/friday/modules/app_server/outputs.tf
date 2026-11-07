output "public_ip" {
    description = "Public IP address of the instance"
    value       = aws_instance.this.public_ip
}

output "instance_id" {
    description = "EC2 Instance ID"
    value       = aws_instance.this.id
}