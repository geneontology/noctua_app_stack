# Deploying Noctua App Stack On 

Install app stack using ansible on a single machine

## Requirements 

- The steps below were successfully tested using:
    - Terraform (v0.14.4)

## Install Terraform


### Create AWS instance: 


```sh
terraform -chdir=aws init
terraform -chdir=aws plan
terraform -chdir=aws apply

# To view the outputs
terraform -chdir=aws output 

#To view what was deployed:
terraform -chdir=aws show 

```

### Test Instance: 

```sh
export HOST=`terraform output public_ip`
export PRIVATE_KEY=`terraform output private_key_path`

ssh -o StrictHostKeyChecking=no -i $PRIVATE_KEY ubuntu@$HOST
docker ps
which docker-compose
```

### Stage to AWS Instance: 

Assuming you have built the docker images and pushed them to dockerhub using 
build_images and push_images playbooks as explained in [this document](../README.md)

```sh
export HOST=`terraform output public_ip`
export PRIVATE_KEY=`terraform output private_key_path`
ansible-playbook -e "stage_dir=/home/ubuntu/stage_dir" -e "host=$HOST" --private-key $PRIVATE_KEY  -u ubuntu -i "$HOST,"  stage.yaml
```

### Bring Up The Stack: 

```
ssh -o StrictHostKeyChecking=no -i $PRIVATE_KEY ubuntu@$HOST
docker-compose -f stage_dir/docker-compose-golr.yaml
#When the stack is up you can access it from broswer on port 8080 and using aws instance's public ip. 
```

