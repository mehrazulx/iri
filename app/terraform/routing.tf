



# Public route table______________________________________________________________________________________
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.existing.id

  tags = {
    Name = "NEW-RT"
  }
}

# Route to Internet via IGW________________________________________________________________________________
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate public subnet with public route table________________________________________________________________________________
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.existing_public.id
  route_table_id = aws_route_table.public.id
}

# Associate public subnet #2 with public route table---------------------------------------------------------------------
resource "aws_route_table_association" "public_2"{
  subnet_id      = aws_subnet.existing_public_2.id
  route_table_id = aws_route_table.public.id
}
