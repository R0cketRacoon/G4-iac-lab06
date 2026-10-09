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