output "idEndpointS3" {
  description = "ID del gateway endpoint de S3."
  value       = aws_vpc_endpoint.endpoint_gateway_s3.id
}