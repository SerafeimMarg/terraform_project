<!-- Thoughts

- [ ] Authorization must be managed(the way access keys are provided): Have created on IAM user group with specific policies enabled, so the user created for this project's purpose 
has only needed permissions for resource provisioning
- [ ]application resilience with Avail Zones
- [ ]separate envs? dev, staging, production, testing(QA)
- [ ]how data will be stored for ssh ing into ec2 instances
- [ ]how data will be pulled regarding AMI info(hardcoded or not?choose specific debian ami replicating it into only for me?)

-->
---
# VPC creation

VPC subnets? Purpose?

# Security Group creation

# EC2 creation

# Load Balancer creation

# AutoScaling Group creation

# Wrap all of this in Terragrunt(OPTIONAL)

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



