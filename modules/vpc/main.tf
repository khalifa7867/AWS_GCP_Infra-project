

#create vpc
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true


    tags = {
        Name = "${var.vpc_name}-vpc"
        envinorment = var.envinorment
        project_name = var.Project_name
    }
  
}

#create internet gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.my_vpc.id

    tags = {
        Name = "${var.vpc_name}-igw"
        envinorment = var.envinorment
        project_name = var.Project_name
    }
}

#create public subnet
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.my_vpc.id

    count = length(var.aws_public_subnets)
  cidr_block = var.aws_public_subnets[count.index]

tags = merge(var.public_subnet_tags, {
  "Name" = "${var.vpc_name}-public-subnet"
  "envinorment" = var.envinorment
  "project_name" = var.Project_name
  type = "public"})

  availability_zone = var.azs[count.index]

depends_on = [aws_internet_gateway.IGW]

}

#create private subnet
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.my_vpc.id

    count = length(var.aws_private_subnets)
  cidr_block = var.aws_private_subnets[count.index]
    availability_zone = var.azs[count.index]
    
        tags = merge(var.private_subnet_tags, {
            Name = "${var.vpc_name}-private-subnet"
            envinorment = var.envinorment
            project_name = var.Project_name
             type = "private"}) 
           
}

#create eip
resource "aws_eip" "nat_gateway_eip" {
   domain = "vpc"
   count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.aws_public_subnets)) : 0
    
        tags = {
            Name = "nat-gateway-eip"
            envinorment = var.envinorment
            project_name = var.Project_name
        }

        depends_on = [ aws_internet_gateway.IGW ]
}

#create nat gateway
resource "aws_nat_gateway" "enable_nat_gateway" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.aws_public_subnets)) : 0
  allocation_id = aws_eip.nat_gateway_eip[count.index].id
  subnet_id = aws_subnet.public[count.index].id
    
        tags = {
            Name = "nat-gateway"
            envinorment = var.envinorment
            project_name = var.Project_name
        }

        depends_on = [ aws_internet_gateway.IGW, aws_eip.nat_gateway_eip, aws_subnet.public ]
}

#associate public subnet with route table
resource "aws_route_table_association" "public_subnets" {
    count          = length(aws_subnet.public)
    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.aws_public_rout_table.id   

    depends_on = [ aws_route_table.aws_public_rout_table ]
}

#route for public subnet to internet gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id = aws_route_table.aws_public_rout_table.id
  gateway_id     = aws_internet_gateway.IGW.id
    destination_cidr_block = "0.0.0.0/0"

depends_on = [ aws_route_table.aws_public_rout_table ]
}

#create public route table
resource "aws_route_table" "aws_public_rout_table" {
    vpc_id = aws_vpc.my_vpc.id

     tags = {
            Name = "${var.vpc_name}-public-rt"
            envinorment = var.envinorment
            project_name = var.Project_name
        }
} 




#create private route table
resource "aws_route_table" "aws_private_rout_table" {
    count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(aws_subnet.private)) : 0
    vpc_id = aws_vpc.my_vpc.id

     tags = {
            Name = "${var.vpc_name}-private-rt"
            envinorment = var.envinorment
            project_name = var.Project_name
        }
}


#route for private subnet to nat gateway
resource "aws_route" "private_nat_gateway" {
    count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(aws_subnet.public)) : 0
  route_table_id         = aws_route_table.aws_private_rout_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.enable_nat_gateway[count.index].id

  depends_on = [ aws_route_table.aws_private_rout_table ]
}

resource "aws_route_table_association" "private_subnets" {
    count          = length(aws_subnet.private)
    subnet_id      = aws_subnet.private[count.index].id
    route_table_id = var.single_nat_gateway ? aws_route_table.aws_private_rout_table[0].id : aws_route_table.aws_private_rout_table[count.index].id

    depends_on = [ aws_route_table.aws_private_rout_table ]
  
}




