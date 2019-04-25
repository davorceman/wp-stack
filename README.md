# wp-stack
AWS - WP stack including MariaDB Galera cluster, HAProxy LB, Jenkins server  
Purpose of this project is practicing and learning AWS, CI/CD, Jenkins Terraform, Ansible, Git, MariaDB Galera cluster and HAProxy setup.  

Stack will looks like this:  
https://www.lucidchart.com/invitations/accept/b58d827c-668d-4fd4-a1f0-a2bd519c867d  

![alt text](https://github.com/davorceman/wp-stack/blob/master/chart.png)

Short guide
 - Install terraform. Ansible is not mandatory, because all scripts will be executed from "Tools" server.
 - Create AWS user and set profile with "aws configure"
 - With command ssh-keygen create private and public key
 - Modify terraform.tfvars, and take attention mypublicip variable.
 - Set variables in ansible yml files. Next version of this setup will separate variables in another file.
 - aws_hosts and variables.yml are dinamicaly created files.
 
 Start script:

 >$ terraform init   # Initialize a working directory  
 $ terraform plan   # Check if everything is OK, no errors  
 $ terraform apply  

 
 And that is it. In about 10 minutes you will have stack up and runing. 
 Just finalize Manually Jenkins installation, and install ssh plugin. Access to it with http://<ToolsServerPublicIP>:8080
 For now WordPress is excluded from this scripts, because I wanted to set deploy with Jenkins.
 
 So create new github repo, create Personal access token and set webhooks
 For first deploy at this moment for build I'm using these scripts

For first web server:  
 >   #!/bin/bash  
    cd /var/www/vhosts/wp.ceman.cc/htdocs/  
    git clone git@github.com:davorceman/s-wp.git .  
    wp core config --dbname='WordPress' --dbuser='WPuser-vQ93NM' --dbpass='N59M7Vhdwm6jPp6b' --dbhost='10.0.2.155' --dbprefix='wpcmncc_'  
    wp core install --url=wp.ceman.cc --title="WP Site" --admin_user=ceman --admin_password='N59M7Vhdwm6jPp6b' --admin_email='test@example.com'  
    sudo chown -R apache:apache /var/www/vhosts/wp.ceman.cc/htdocs/  
    sudo find /var/www/vhosts/wp.ceman.cc/htdocs -type d -exec chmod 775 {} \;  
    sudo find /var/www/vhosts/wp.ceman.cc/htdocs -type f -exec chmod 664 {} \;  

For second web server: (Difference is that this server will be connected to second node of MariaDB Galera cluster, and there is no need for setting up database)  
>    #!/bin/bash  
    cd /var/www/vhosts/wp.ceman.cc/htdocs/  
    git clone git@github.com:davorceman/s-wp.git .  
    wp core config --dbname='WordPress' --dbuser='WPuser-vQ93NM' --dbpass='N59M7Vhdwm6jPp6b' --dbhost='10.0.3.59' --dbprefix='wpcmncc_'  
    sudo chown -R apache:apache /var/www/vhosts/wp.ceman.cc/htdocs/  
    sudo find /var/www/vhosts/wp.ceman.cc/htdocs -type d -exec chmod 775 {} \;  
    sudo find /var/www/vhosts/wp.ceman.cc/htdocs -type f -exec chmod 664 {} \;  


Then I created second Jenkins project for auto-deploy with github webhooks, On every commit and push to github, build will execute this script on both server:
>    #!/bin/bash  
    cd /var/www/vhosts/wp.ceman.cc/htdocs/  
    git pull origin master  
    
At this moment I'm thinking about next tasks for this project:
- Turn on and setup selinux on all servers
- Tweak a little bit MySQL (log paths etc...)
- Tweak HAProxy server. Install Let's Encrypt
- Properly arrange ansible playbooks using roles.
- To try to shorten these scrits with "with-items"
- Improve Idempotency for Ansible scripts
- Add route53 records to hosted zones with terraform.
