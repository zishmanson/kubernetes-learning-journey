resource "aws_dynamodb_table" "tasks" {
  name           = "${var.project_name}-tasks"
  billing_mode   = "PAY_PER_REQUEST" # On-demand pricing, no need to provision capacity
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Enable point-in-time recovery for production
  point_in_time_recovery {
    enabled = var.environment == "prod"
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-tasks-table"
    }
  )
}

# Optional: DynamoDB table for application state/config
resource "aws_dynamodb_table" "app_config" {
  name           = "${var.project_name}-config"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "key"

  attribute {
    name = "key"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-config-table"
    }
  )
}
