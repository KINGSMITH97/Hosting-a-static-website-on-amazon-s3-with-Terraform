#create an s3 bucket

resource "aws_s3_bucket" "s3_website" {
  bucket = var.bucket_name

  tags = {
    Name = "s3_website"
  }
}

#create the owner of the bucket
resource "aws_s3_bucket_ownership_controls" "bucket_owner" {
  bucket = aws_s3_bucket.s3_website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#make the bucket publicly accessible
resource "aws_s3_bucket_public_access_block" "s3_public_access" {
  bucket = aws_s3_bucket.s3_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

#making the bucket's access control public also
resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket_owner,
    aws_s3_bucket_public_access_block.s3_public_access,
  ]

  bucket = aws_s3_bucket.s3_website.id
  acl    = "public-read"
}

data "local_file" "website_files" {
  for_each = fileset(var.website_path, "**/*")

  filename = "${var.website_path}${each.value}"
}

locals {
  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
    "txt"  = "text/plain"
    # Add more extensions and their MIME types as needed
  }
}

resource "aws_s3_object" "website_content" {
  for_each = fileset("${var.website_path}", "**/*")
  bucket   = aws_s3_bucket.s3_website.id
  key      = each.value
  source   = "${var.website_path}${each.value}"
  etag     = filemd5("${var.website_path}${each.value}")

  acl = "public-read"


  content_type = lookup(local.mime_types, split(".", each.value)[1], "text/html")

}

resource "aws_s3_bucket_website_configuration" "host_static_website" {
  bucket = aws_s3_bucket.s3_website.id

  index_document {
    suffix = "index.html"

  }

  error_document {
    key = "error.html"
  }


  depends_on = [
    aws_s3_bucket_acl.bucket_acl
  ]
}


