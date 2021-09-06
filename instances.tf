resource "aws_instance" "webservers" {
	count = length(var.azs) 
	ami = var.webservers_ami
	instance_type = var.instance_type
	security_groups = [aws_security_group.allow-ssh.id]
	subnet_id = element(aws_subnet.private-subnet.*.id,count.index)
	user_data = file("install_httpd.sh")

	tags = {
	  Name = "webserver-${count.index}"
	}
}

# Create a new load balancer
resource "aws_elb" "webserver-elb" {
    name = "webserver-elb"
    #availability_zones = {var.azs}
    subnets = (aws_subnet.public-subnet.*.id)
    security_groups = ["${aws_security_group.allow-ssh.id}"]

    listener {
        instance_port = 80
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }

    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        target = "HTTP:80/index.html"
        interval = 30
    }

    instances = (aws_instance.webservers.*.id)
    cross_zone_load_balancing = true
    idle_timeout = 100
    connection_draining = true
    connection_draining_timeout = 300

    tags = {
        Name = "webserver-elb"
    }
}