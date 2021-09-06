# vpc
resource "aws_vpc" "my-vpc" {
    cidr_block          = "172.16.0.0/16"
    enable_dns_support  = "true"
    enable_dns_hostnames = "true"
    
    tags = {
        Name = "my-vpc"
    }
}

# internet gateway
resource "aws_internet_gateway" "myInternetGateway" {
    vpc_id              = aws_vpc.my-vpc.id

    tags = {
        Name            = "myInternetGateway"
    }
}

# Public subnets
resource "aws_subnet" "public-subnet" {
    count               = length(var.azs)
    vpc_id              = aws_vpc.my-vpc.id
    cidr_block          = "172.16.${1+count.index}.0/24"
    availability_zone   = element(var.azs,count.index)

    tags = {
        Name = "PublicSubnet-${count.index+1}"
    }
}

# Private subnet
resource "aws_subnet" "private-subnet" {
    count               = length(var.azs)
    vpc_id              = aws_vpc.my-vpc.id
    cidr_block          = "172.16.${10+count.index}.0/24"
    availability_zone   = element(var.azs,count.index)

    tags = {
        Name = "PrivateSubnet-${count.index+1}"
    }
}


# Public route table
resource "aws_route_table" "public" {
    vpc_id              = aws_vpc.my-vpc.id
    route {
        cidr_block      = "0.0.0.0/0" 
        gateway_id      = aws_internet_gateway.myInternetGateway.id
  } 
    tags = { 
        Name = "public_route"
  } 
}

# route table association for public subnets
resource "aws_route_table_association" "public" {
    count               = length(var.azs)
    subnet_id           = element(aws_subnet.public-subnet.*.id, count.index)
    route_table_id      = aws_route_table.public.id
}

# EIP for NAT gateway 
resource "aws_eip" "nat" {
    vpc                 = true 
}  

# nat gateway
resource "aws_nat_gateway" "nat-gw" {
    allocation_id       = aws_eip.nat.id
    subnet_id           = element(aws_subnet.public-subnet.*.id, 1)
    depends_on          = [aws_internet_gateway.myInternetGateway]
} 

# private route table 
resource "aws_route_table" "private" {
    vpc_id              = aws_vpc.my-vpc.id
    route {
        cidr_block      = "0.0.0.0/0"
        nat_gateway_id  = aws_nat_gateway.nat-gw.id
    }
     
    tags = { 
        Name            = "private_route" 
    } 
}

# route table association for the private subnets 
resource "aws_route_table_association" "private" {
    count               = length(var.azs)
    subnet_id           = element(aws_subnet.private-subnet.*.id, count.index)
    route_table_id      = aws_route_table.private.id
}

# security group
resource "aws_security_group" "allow-ssh" {
    name            = "webserver-sg"
    vpc_id          = aws_vpc.my-vpc.id

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "webserver-sg"
    }
}