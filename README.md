<!-- Thoughts

- [ ] Authorization must be managed(the way access keys are provided): Have created on IAM user group with specific policies enabled, so the user created for this project's purpose 
has only needed permissions for resource provisioning
- [ ]application resilience with Avail Zones
- [ ]separate envs? dev, staging, production, testing(QA) : For this either create separate folders with terraform.tfvars files and initialise from the different folders but with
                                                            same manifest files' path kai stis alles entoles
                                                             or work in different workspaces
sto production kalo tha tan na xame 4 instances gia load balanced env
opote dev 1 instance
kai QA- staging 2 instances
kai prod 4 instances
- [ ]how data will be stored for ssh ing into ec2 instances
- [ ]how data will be pulled regarding AMI info(hardcoded or not?choose specific debian ami replicating it into only for me?)
-not server in 1 AZ and subnet in another

CUSTOM MODULES? or use the ones provided by hashicorp/aws

S3 backend to store remote state
REMOTE STATE IMPORTANT using Jenkins so that when 2 terraform deployment jobs execute the same time the Jenkins will prevent this
store secrets in jenkins at manage jenkins->manage credentials

On prod env we would have to define CNAME variable for the managed DNS we use
for dev we let aws create a DNS so that we can use to reach the instance

netstat -lntpu
-->
# Packer Setup
Chose Packer to build custom AMIs from Debian11 installing NginX that will be used later on from each EC2 instance created
Using packer we ensure immutability of our infra.

- Install packer 
- Set the 2 environmental variables ACCESS_KEY and SECRET_KEY (using export or setx depending on OS)
- Run ```packer build -var-file=variables.json main.json```

The above are prerequisite! 
After this step you can apply terraform's plan, so that a custom AMI exists in AWS
---
# Terraform Setup
- Install terraform
- Run 
```
terraform init
terraform plan
terraform apply
```
## Network Configuration

Created a VPC to 10.0.0.0/16
Created also 2 different subnets for 2 different AZs to be used by Load Balancer Later and have higher resilience
(The above 2 subnets are created for dev type of setup)
Created a Internet Gateway for communication between the VPC and the Internet and vice versa
Created NAT Gateway for communication from VPC resources to the Internet

## Security Group creation
Created SG with required rules to be used by aws_launch_template for the autoscale group we want to create: 
- Inbound: 80/HTTP(VPC CIDR only), 22/SSH(all)
- Outbound: all

Created another SG specifically for the ELB to allow traffic through the ELB to the attached instances in the same VPC
- Inbound: 80
- Outbound: all

## Load Balancer
Chose ElasticLoadBalancer(CLB) which has support both for HTTP(S) and TCP
We also set different subnets(2 in our case but could be more) for different AZ so that we will prevent, e.g. a zone specific unexpected outage, and all traffic will be directed to another AZ
Added health_checks and a listener to port 80

# AutoScaling Group creation
Created a aws_launch_template in which:
    - AMI id fetched from data is the most recent AMI created by the packer build command(prerequisite)
    - Created a key_pair resource which basically creates the tf_key.pem(private_key) required to ssh into the instances

Created autoscale_group in which the min and desired capacity is 2
Created an aws_autoscaling_attachment for ELB and ASG attachment 

To ssh into an instance we run:
``` 
chmod 400 tf_key.pem
ssh -i "tf_key.pem" admin@<ec2_instance_ip>

```
We can also use the "dns_name" output variable to test using curl the commention.
<!-- Thoughts
---
### TASK

Using Terraform and AWS, create a new VPC. In this new VPC create: 
- [ ]1. An autoscaling group of 2 (min) t3.micro EC2 instances running Debian 11. 2. The EC2 instances should provision and run nginx. 
- [ ]3. A Load Balancer attached to the autoscaling group. 
- [ ]4. Security groups for the EC2 instances should: 
    - [ ]a. Allow ingress to port 80 (HTTP) only from the VPC’s CIDR. 
    - [ ]b. Allow ingress to port 22 (SSH) from all networks. 
    - [ ]c. Allow all egress traffic. 

Notes: 
[*] You may use AWS Free Tier 
[*] You decide on what VPC subnets you create, if any 
[*] Document your architecture decisions in a README file 
[*] Bonus points if you use Terragrunt (not obligatory) 
[*] Code should be delivered via a link to a public git repository (you should omit ssh keys but document how to provide them) 
-->