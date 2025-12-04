output "buckets" {
  description = "Map of created buckets"
  value = {
    for k, v in google_storage_bucket.buckets : k => {
      name      = v.name
      url       = v.url
      self_link = v.self_link
      location  = v.location
    }
  }
}

output "bucket_urls" {
  description = "Map of bucket names to their URLs"
  value = {
    for k, v in google_storage_bucket.buckets : k => v.url
  }
}