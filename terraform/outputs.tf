# outputs.tf
output "instance_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.travos_terraform.public_ip
}
