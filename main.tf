provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

################################################################
##### VPC, IGW, Route Tables, Subnets, Subnet Associations, NAT Gateway ######

resource "aws_vpc" "symphony_vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "symphony-vpc"
  }
}

resource "aws_subnet" "public1" {
    vpc_id = "${aws_vpc.symphony_vpc.id}"
    cidr_block = "${var.subnet_cidrs["public1"]}"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    map_public_ip_on_launch = true

    tags = {
      Name = "symphony-subnet-public1"
    }
}
resource "aws_subnet" "public2" {
    vpc_id = "${aws_vpc.symphony_vpc.id}"
    cidr_block = "${var.subnet_cidrs["public2"]}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    map_public_ip_on_launch = true

    tags = {
      Name = "symphony-subnet-public2"
    }
}

resource "aws_subnet" "private1" {
    vpc_id = "${aws_vpc.symphony_vpc.id}"
    cidr_block = "${var.subnet_cidrs["private1"]}"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    map_public_ip_on_launch = false

    tags = {
      Name = "symphony-subnet-private1"
    }
}

resource "aws_subnet" "private2" {
    vpc_id = "${aws_vpc.symphony_vpc.id}"
    cidr_block = "${var.subnet_cidrs["private2"]}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    map_public_ip_on_launch = false

    tags = {
      Name = "symphony-subnet-private2"
    }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.symphony_vpc.id}"

  tags = {
    Name = "symphony-igw"
  }
}

resource "aws_eip" "nat" {
  vpc      = true
}

resource "aws_nat_gateway" "symphony-nat-gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public2.id}"

  tags = {
    Name = "Symphony NAT Gateway"
  }
}
resource "aws_route_table" "publicrt" {
  vpc_id = "${aws_vpc.symphony_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name = "symphony-publicrt"
  }
}

resource "aws_default_route_table" "privatert" {
  default_route_table_id = "${aws_vpc.symphony_vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.symphony-nat-gw.id}"
  }

    tags = {
      Name = "symphony-privatert-main"
    }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = "${aws_subnet.public1.id}"
  route_table_id = "${aws_route_table.publicrt.id}"
}

resource "aws_route_table_association" "public2" {
  subnet_id      = "${aws_subnet.public2.id}"
  route_table_id = "${aws_route_table.publicrt.id}"
}

resource "aws_route_table_association" "private1" {
  subnet_id      = "${aws_subnet.private1.id}"
  route_table_id = "${aws_default_route_table.privatert.id}"
}

resource "aws_route_table_association" "private2" {
  subnet_id      = "${aws_subnet.private2.id}"
  route_table_id = "${aws_default_route_table.privatert.id}"
}

################################################################
######################## Security Groups #######################

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP/HTTPS"
  vpc_id      = "${aws_vpc.symphony_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

    tags = {
    Name = "symphony-web_sg"
  }
}

resource "aws_security_group" "tools_sg" {
  name        = "ssh_sg"
  description = "Allow SSH and Jenkins"
  vpc_id      = "${aws_vpc.symphony_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.mypublicip}"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.mypublicip}"]
  }
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["185.199.108.0/22","192.30.252.0/22","140.82.112.0/20"] # github ports for webhooks
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

    tags = {
      Name = "symphony-tools_sg"
  }
}

resource "aws_security_group" "all-from-lan_sg" {
  name        = "all-from-lan_sg"
  description = "Open all ports for local access"
  vpc_id      = "${aws_vpc.symphony_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

    tags = {
      Name = "symphony-all-from-lan_sg"
  }
}
################################################################
######################### EC2 instances ########################

resource "aws_key_pair" "symphony-key" {
  key_name   = "symphony-key"
  public_key = "${var.public_key}"
}

resource "aws_instance" "DB1" {
  ami           = "${var.EC2_ami}"
  instance_type = "${var.EC2_type}"
  key_name = "${aws_key_pair.symphony-key.key_name}"
  subnet_id = "${aws_subnet.private1.id}"
  vpc_security_group_ids = ["${aws_security_group.all-from-lan_sg.id}"]
  
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = "true"
  }

  tags = {
    Name = "DB1"
  }
}

resource "aws_instance" "DB2" {
  ami           = "${var.EC2_ami}" 
  instance_type = "${var.EC2_type}"
  key_name = "${aws_key_pair.symphony-key.key_name}"
  subnet_id = "${aws_subnet.private2.id}"
  vpc_security_group_ids = ["${aws_security_group.all-from-lan_sg.id}"]
  
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = "true"
  }
  

  tags = {
    Name = "DB2"
  }

}

resource "aws_instance" "WebSRV1" {
  ami           = "${var.EC2_ami}"
  instance_type = "${var.EC2_type}"
  key_name = "${aws_key_pair.symphony-key.key_name}"
  subnet_id = "${aws_subnet.private1.id}"
  vpc_security_group_ids = ["${aws_security_group.all-from-lan_sg.id}"]

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = "true"
  }

  tags = {
    Name = "WebSRV1"
  }
}

resource "aws_instance" "WebSRV2" {
  ami           = "${var.EC2_ami}"
  instance_type = "${var.EC2_type}"
  key_name = "${aws_key_pair.symphony-key.key_name}"
  subnet_id = "${aws_subnet.private2.id}"
  vpc_security_group_ids = ["${aws_security_group.all-from-lan_sg.id}"]
  
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = "true"
  }

  tags = {
    Name = "WebSRV2"
  }
}

resource "aws_instance" "LB1" {
  ami           = "${var.EC2_ami}"
  instance_type = "${var.EC2_type}"
  key_name = "${aws_key_pair.symphony-key.key_name}"
  subnet_id = "${aws_subnet.public1.id}"
  vpc_security_group_ids = ["${aws_security_group.web_sg.id}", "${aws_security_group.all-from-lan_sg.id}"]
    
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = "true"
  }
 
  tags = {
    Name = "LB1"
  }
}

resource "aws_instance" "LB2" {
  ami           = "${var.EC2_ami}"
  instance_type = "${var.EC2_type}"
  key_name = "${aws_key_pair.symphony-key.key_name}"
  subnet_id = "${aws_subnet.public2.id}"
  vpc_security_group_ids = ["${aws_security_group.web_sg.id}", "${aws_security_group.all-from-lan_sg.id}"]
    
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = "true"
  }
 
  tags = {
    Name = "LB2"
  }
}

resource "aws_instance" "Tools" {
  ami           = "${var.EC2_ami}"
  instance_type = "${var.EC2_type}"
  key_name = "${aws_key_pair.symphony-key.key_name}"
  subnet_id = "${aws_subnet.public1.id}"
  vpc_security_group_ids = ["${aws_security_group.tools_sg.id}", "${aws_security_group.all-from-lan_sg.id}"]
    
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = "true"
  }

  provisioner "file" {
    source = "/home/ansibleuser/.ssh/Just4Fun-Frankfurt.pem"
    destination = "/home/centos/.ssh/id_rsa"
    connection {
      type = "ssh"
      user = "centos"
      private_key = "${file("${var.private_key}")}"
    }
  }

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF > ansible/aws_hosts
[dbs]
${aws_instance.DB1.private_ip}
${aws_instance.DB2.private_ip}
[webs]
${aws_instance.WebSRV1.private_ip}
${aws_instance.WebSRV2.private_ip}
[lbs]
${aws_instance.LB1.private_ip}
${aws_instance.LB2.private_ip}
[tools]
${aws_instance.Tools.public_ip}
EOF
cat <<EOF > ansible/dynamic-variables.yml
---
db1_host: ${aws_instance.DB1.private_ip}
db2_host: ${aws_instance.DB2.private_ip}
web1_host: ${aws_instance.WebSRV1.private_ip}
web2_host: ${aws_instance.WebSRV2.private_ip}
lb1_instanceID: ${aws_instance.LB1.id}
lb2_instanceID: ${aws_instance.LB2.id}
lb1_EIP: ${aws_eip.LB_eip.public_ip}
lb1_EIP_assoc: ${aws_eip.LB_eip.association_id}
EOF
EOD
  }

  provisioner "file" {
    source = "ansible/"
    destination = "/home/centos"
    connection {
      type = "ssh"
      user = "centos"
      private_key = "${file("${var.private_key}")}"
    }
  }


  provisioner "remote-exec" {
    inline = [
      "sudo yum install epel-release -y",
      "sudo yum update -y",
      "sudo yum install ansible -y",
      "touch ~/.ansible.cfg",
      "echo '[defaults]' > ~/.ansible.cfg",
      "echo 'host_key_checking = False' >> ~/.ansible.cfg",
      "chmod -R 700 ~/",
      "ansible-playbook -i aws_hosts ~/db.yml",
      "ansible-playbook -i aws_hosts ~/web.yml",
      "ansible-playbook -i aws_hosts ~/lb.yml",
      "ansible-playbook ~/tools.yml"
   ]
    connection {
      type = "ssh"
      user = "centos"
      private_key = "${file("${var.private_key}")}"
    }

  }

  tags = {
    Name = "Tools"
  }
}

 resource "aws_eip" "LB_eip" {
  instance = "${aws_instance.LB1.id}"
  vpc      = true
}

 resource "aws_eip" "Tools_eip" {
  instance = "${aws_instance.Tools.id}"
  vpc      = true
}