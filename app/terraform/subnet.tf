#Public Subnet 1____________________________________________________________________________________________
resource "aws_subnet" "existing_public" {
  vpc_id = aws_vpc.existing.id
  cidr_block = "10.2.1.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true


  tags = {
    name = "${var.project_name}-public-subnet-1"
  }
}

#Public Subnet 2------------------------------------------------------------------------------------------
resource "aws_subnet" "existing_public_2" {
  vpc_id = aws_vpc.existing.id
  cidr_block = "10.2.2.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true


  tags = {
    name = "${var.project_name}-public-subnet-2"
  }

}