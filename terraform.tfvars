aws_profile = "terransible"
aws_region  = "eu-central-1"
vpc_cidr    = "10.0.0.0/16"
subnet_cidrs = {
    public1  = "10.0.1.0/24"
    private1 = "10.0.2.0/24"
    private2 = "10.0.3.0/24"
}
mypublicip  = "87.116.176.196/32"
EC2_ami    = "ami-04cf43aca3e6f3de3"
EC2_type            = "t2.micro"
public_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCb7wKx4eOEWKYQoBGrIMoudI1nggmZgtonNfRnZ6oXM9Q+yjAn+zrM/GugRXUbS/ZomltRBJiOxIBrwnStqzE7aI2eoP429RDr+nBMQb+Oxa6FBn8plP1WO2iEcxbdP24RYH2P8FCOPrsGdqT0iFfitQhs11siAx0NJtYAc45c5S1FUe2hjNXzhGw1C3M5Ivy3P+Bw0fLDw0q7sIaxsnpi8i5Q+dxDo7ugyN5j68phZCLmHz2OvpFDP8Zb0+/ebYWMvIpzDlLIA1ZNunayp1LruEVvsyqQY3CbVRShZF3Vain9mhj60vhUywz2HMSpJ8WGRKPzN7VeOG1SkktS9PEX Just4Fun-Frankfurt"
private_key         = "/home/ansibleuser/.ssh/Just4Fun-Frankfurt.pem"
