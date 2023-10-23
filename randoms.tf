
resource "random_pet" "rg_name" {
 prefix = "dscom"
}

resource "random_string" "instance_string" {
 length = 8
 special = false
 upper = false
}
