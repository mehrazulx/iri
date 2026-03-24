# Internet Gateway________________________________________________________________________________________
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.existing.id

  tags = {
    Name = "NEW-IGW"
  }
}