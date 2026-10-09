resource "random_id" "sufijo_bucket" {
  byte_length = 4
}

resource "aws_s3_bucket" "bucket_imagenes" {
  bucket        = "${var.nombreBase}-images-${random_id.sufijo_bucket.hex}"
  force_destroy = var.permitirDestruccionBucket

  tags = {
    Name = "${var.nombreBase}-images"
  }
}

resource "aws_s3_bucket_public_access_block" "bloqueo_acceso_publico" {
  bucket = aws_s3_bucket.bucket_imagenes.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_ownership_controls" "propiedad_objetos" {
  bucket = aws_s3_bucket.bucket_imagenes.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}