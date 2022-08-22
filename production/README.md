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

Use DNS records for noctua and barista. Once the stack is ready you would need to point these to elastic ip address of the stack,  

## Golr/Amigo
Use the dns name of the external golr instance running alongside amigo

## Provision to AWS

Copy sample files and modify as needed. For the terraform worksapce we append the date.
As an example we use production-yy-mm-dd

```
cp ./production/backend.tf.sample aws/backend.tf
cp ./production/config-instance.yaml.sample config-instance.yaml
go-deploy -init -c config-instance.yaml -w production-yy-mm-dd -d aws -verbose
cp ./production/config-stack.yaml.sample config-stack.yaml
go-deploy -c config-stack.yaml -w production-yy-mm-dd -d aws -verbose
```

## Access noctua from a browser
The elastic public ip address shows up in the logs when deploying but it can also be found in production-yy-mm-dd.cfg
Point the noctua and barista DNS entries mentioned above to this ip address

- Use `http://{public_ip}`

## Destroy Instance And Stack

```sh
# Make sure you pointing to the correct workspace
terraform -chdir=aws workspace show
terraform -chdir=aws destroy
```
