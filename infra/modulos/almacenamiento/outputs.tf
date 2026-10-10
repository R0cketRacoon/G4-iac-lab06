output "nombreBucketImagenes" {
  description = "Nombre real del bucket, con el sufijo aleatorio."
  value       = aws_s3_bucket.bucket_imagenes.id
}

output "arnBucketImagenes" {
  description = "ARN del bucket, para políticas de IAM y del endpoint."
  value       = aws_s3_bucket.bucket_imagenes.arn
}