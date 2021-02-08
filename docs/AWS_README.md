# Provision AWS instance.

## Requirements 

- The steps below were successfully tested using:
    - Terraform (v0.14.4)

#### Install Terraform

- Go to [url](https://learn.hashicorp.com/tutorials/terraform/install-cli)

#### AWS Credentials.
- Create a file or override the location in aws/provider.tf

```
[default]
aws_access_key_id = XXXX
aws_secret_access_key = XXXX
```
#### SSH Credentials.
- In aws/vars.tf the private key and the public keys are assumed to be in the standard location

```
variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

```

#### TAGGING
- Overide the tag used in vars.tf

```
variable "tags" {
  type = map
  default = { Name = "testing-noctua-app-stack" }
}
```
#### Create AWS instance: 

Note: Terraform creates some folders and files to maintain the state. Use <i>ls -a aws</i>

```sh
# This will install the aws provider. 
terraform -chdir=aws init

# Validate the config
terraform -chdir=aws validate

# View what is going to be created. The plan.
terraform -chdir=aws plan

# This will create the vpc, security group and the instance
terraform -chdir=aws apply

# To view the outputs
terraform -chdir=aws output 

#To view what was deployed:
terraform -chdir=aws show 

```

#### Test Instance: 

```sh
export HOST=`terraform -chdir=aws output -raw public_ip`
export PRIVATE_KEY=`terraform -chdir=aws output -raw private_key_path`

ssh -o StrictHostKeyChecking=no -i $PRIVATE_KEY ubuntu@$HOST
docker ps
which docker-compose
```

#### Stage to AWS Instance: 

Assuming you have built the docker images and pushed them to dockerhub using 
build_images and push_images playbooks as explained in [this document](../README.md)

```sh
export HOST=`terraform -chdir=aws output -raw public_ip`
export PRIVATE_KEY=`terraform -chdir=aws output -raw private_key_path`
ansible-playbook -e "stage_dir=/home/ubuntu/stage_dir" -e "host=$HOST" --private-key $PRIVATE_KEY  -u ubuntu -i "$HOST,"  stage.yaml
```

### Bring Up The Stack: 

```
ssh -o StrictHostKeyChecking=no -i $PRIVATE_KEY ubuntu@$HOST
docker-compose -f stage_dir/docker-compose-golr.yaml up -d
#When the stack is up you can access it from broswer on port 8080 and using aws instance's public ip. 
```

### Destroy instance:
```
terraform -chdir=aws destroy
```


