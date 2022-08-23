# Noctua Production Deployment

This repository enables the deployment of the noctua stack to AWS. It includes 
minerva, barista, and noctua and it points to an external amigo instance.     

## Deploy a version of the Noctua editor (including minerva, barista, noctua):
  - Important ansible files:
    - vars.yaml
    - docker-vars.yaml
    - s3-vars.yaml
    - stage.yaml
    - start_services.yaml
  
## Artifacts Deployed To Staging directory On AWS:
  - blazegraph.jnl
  - Cloned repositories:
    - noctua-form, noctua-landing-page, noctua-models, go-site and noctua-visual-pathway-editor.
  - s3 credentials used to push apache logs to s3 buckets
  - github OAUTH client id and secret
  - docker-production-compose and various configuration files from template directory

## Requirements
- Terraform
- Ansible
- 
## Install Python deployment Script
Note the script has a <b>-dry-run</b> option.

```
>pip install go-deploy==0.3.0 # requires python >=3.8.5
>go-deploy -h
```

## S3 Terraform Backend

We use S3 terraform backend to store terraform's state. See production/backend.tf.sample

## Github OAUTH
Noctua uses OAUTH for authentication. See templates/github.yaml 

## Prepare Blazegraph journal locally

if you do not have a journal see production/gen_journal.sh.sample to generate one

## DNS 

Use DNS records for noctua and barista. Once the stack is ready you would need to point these to elastic ip address of the stack. For testing purposes you can use aes-test-barista.geneontology.io for barista and aes-test-noctua.geneontology.io for noctua. Once you deploy and have the public ip address got to AWS Route 52 and modify the A records to point to the public IP address

## Golr/Amigo
Use the dns name of the external golr instance running alongside amigo. For testing pourposes you can just use noctua-golr.berkeleybop.org 

## SSH Keys
For testing purposes you can you your own ssh keys. But for production please ask for the go ssh keys.

## S3 Credentials To Push Apache Logs 
These are same as aws credentials but in a different format. See production/s3cfg.sample 

## Provision AWS Instance

Check list:
- [ ] ssh keys
- [ ] <b>Choose your workspace name. We append the date. As an example we use production-yy-mm-dd</b>
- [ ] go-deploy python package has been installed
- [ ] Remember you can use the -dry-run option
- [ ] Execute the commands right below
- [ ] Note down the ip address of the aws instance. This can also be found in production-yy-mm-dd.cfg

```
cp ./production/backend.tf.sample aws/backend.tf
cp ./production/config-instance.yaml.sample config-instance.yaml
go-deploy -init -c config-instance.yaml -w production-yy-mm-dd -d aws -verbose

```

## Deploy Stack to AWS

Check list:
- [ ] <b>DNS names for barista and noctua point to public ip address on AWS Route 53.</b> 
- [ ] Location of SSH keys need to be replaced after copying config-stack.yaml.sample
- [ ] Github credentials will need to be replaced in config-stack.yaml.sample
- [ ] s3 credntials are placed in a file using format described above
- [ ] Location of blazegraph.jnl. This assumes you have generated the journal using steps above
- [ ] Use same workspace name as in previous step
- [ ] Remember you can use the -dry-run option
- [ ] Optional When Testing: change dns names in the config file for noctua, barista, and golr. 
- [ ] Execute the commands right below

```
cp ./production/config-stack.yaml.sample config-stack.yaml
go-deploy -c config-stack.yaml -w production-yy-mm-dd -d aws -verbose
```

## Access noctua from a browser
The elastic public ip address shows up in the logs when deploying but it can also be found in production-yy-mm-dd.cfg
Point the noctua and barista DNS entries mentioned above to this ip address

- Use `http://{public_ip}`

## Debugging

- ssh to machine  username is ubutu
- docker-compose -f stage_dir/docker-compose-production.yaml ps
- docker-compose -f stage_dir/docker-compose-production.yaml down # needed if you make any changes 
- docker-compose -f stage_dir/docker-compose-production.yaml up -d
- docker-compose -f stage_dir/docker-compose-production.yaml logs -f 


## Destroy Instance And Stack

```sh
# Make sure you pointing to the correct workspace
terraform -chdir=aws workspace show
terraform -chdir=aws destroy
```
