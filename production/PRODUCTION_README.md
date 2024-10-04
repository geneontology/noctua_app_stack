# Noctua Production Deployment


This repository enables the deployment of the noctua stack to AWS. It includes 
minerva, barista, and noctua and it points to an external amigo instance. 

 ## Conventions
 Creating and deploying instances on aws involves the creation of multiple artifacts in Route53, EC2, S3...  In order to easily identify all artifacts associated with a workspace instance, a naming convention is utilized.  This allows for easy deletion when a workspace needs to be taken down.   Geneontology dev-ops follows a namespace pattern for workspaces. it is `go-workspace-_______`.  For noctua, it is `go-workspace-noctua`.  Similarly, for the workspace instance, it is namespace pattern `_____-production-YYYY-MM-DD`; e.g.: `graphstore-production-2024-08-26` or `go-api-production-2023-01-30`.  For noctua, it will be `noctua-production-YYYY-MM-DD`.  The details about workspace instance `noctua-production-YYYY-MM-DD` will be stored in the S3 buckets under `go-workspace-noctua`.
 
Login into aws and view the S3 buckets information.  Drill down by selecting 'go-workspace-graphstore'->'env:/'->'production-YYYY-MM-DD'->graphstore->terraform.tfstate.  The Terraform state information can be downloaded.  Specific EC2 instance information details can be viewed by selecting EC2 then clicking on instances and searching for entries with names containing 'production'. There should be an entry for `graphstore-production-YYYY-MM-DD`.  DNS information will be under Route 53.  The hosted zones section will have an entry for 'geneontology.org'


## Prerequisites 
- Before starting, ensure the following are available
1.  aws credentials (aws_access_key_id and aws_secret_access_key)
2.  SSH keys in the shared SpderOak store
3.  github_client_id and github_client_secret  - Github OAuth 
4.  Local instance of Docker
5.  If this system is going to point to existing backend systems for minerva and barista, then determine URLs to access minerva and barista
6.  Blazegraph journal file.  production/gen_journal.sh has instructions on creating one.  Or Download from http://current.geneontology.org/products/blazegraph/blazegraph-production.jnl.gz
7.  Determine the workspace namespace pattern. The namespace will be used multiple times, to make things easier, open up a text editor and enter the namespace example noctua-production-2024-10-02. In addition to noctua, a barista instance will be created and the namespace pattern will be `go-barista-production-YYYY-MM-DD`  The workspace name will be used to instantiate, deploy and destroy.  The 3 commands are as follows:
    - go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose --conf config-instance.yaml
    - go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose --conf config-stack.yaml
    - go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -destroy

The deploy command can be tested before instantiation with the 'dry-run' option:  
    - go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -dry-run  --conf config-stack.yaml
   
The instance name of the server will be noctua-production-YYYY-MM-DD.geneontology.org
A barista instance will be created on go-barista-production-YYYY-MM-DD.geneontology.org

Copy the commands into a text editor and update the workspace name.     

  


## Workflow
In order to ensure reproducibility, a Docker development environment is created locally with the required tools for deployment. Configuration files are updated. These configuration files are used by Terraform and Ansible to instantiate and configure the instances on aws. Once an instance is created on aws, artifacts are deployed to a staging directory on the instance.  Followed by deployment. 

1.  Create a Docker development environment and clone repository from Github
2.  Update credentials for accessing and provisioning resources on aws
3.  Add an entry in the aws s3 for storing information about the workspace being created and initialize
4.  Update configuration file to instantiate instance on aws
5.  Instantiate instance on aws
6.  Update configuration files to deploy on aws
7.  Deploy instance



### 1.  Create a Docker development environment and clone repository from Github
<b>We have a docker based dev environment with all these tools installed.</b> See last section of this README (Appendix I: Development Environment).

The instructions in this document are run from the POV that they are executed within the developement environment; i.e.:
```
docker run --name go-dev -it geneontology/go-devops-base:tools-jammy-0.4.2  /bin/bash
git clone https://github.com/geneontology/noctua_app_stack.git
cd noctua_app_stack
go-deploy -h
```

### 2.  Update credentials for accessing and provisioning resources on aws
####  Copy the ssh keys from your docker host into the running docker image, in `/tmp`:

These commands may have to be executed from a separate terminal that can run Docker commands.
See Prerequisites 2 for keys and copy keys from SpderOak

```
docker cp go-ssh go-dev:/tmp
docker cp go-ssh.pub go-dev:/tmp
```
You should now have the following in your image:
```
ls -latr /tmp
/tmp/go-ssh
/tmp/go-ssh.pub
```
Make sure they have the right permissions to be used:
```
chmod 600 /tmp/go-ssh*
```

####  Establish the AWS credential file
Within the running image, copy and modify the AWS credential file to the default location `/tmp/go-aws-credentials`.

```
cp production/go-aws-credentials.sample /tmp/go-aws-credentials
```

Add your personal dev keys into the file (Prerequisites 1); update the `aws_access_key_id` and `aws_secret_access_key`:
```
emacs /tmp/go-aws-credentials
export AWS_SHARED_CREDENTIALS_FILE=/tmp/go-aws-credentials
```

### 3.  Add an entry in the aws s3 for storing information about the workspace being created and initialize
Update entry for bucket  = `REPLACE_ME_NOCTUA_TERRAFORM_BUCKET` to "go-workspace-noctua"
```
cp ./production/backend.tf.sample ./aws/backend.tf
emacs ./aws/backend.tf
```

Initialize and list buckets
```
go-deploy -init --working-directory aws -verbose
go-deploy --working-directory aws -list-workspaces -verbose
```


### 4. Update configuration file to instantiate instance on aws

Name: REPLACE_ME should be "noctua-production-YYYY-MM-DD" - see Prerequisites 7 for exact text
dns_record_name: should be ["noctua-production-YYYY-MM-DD.geneontology.org", "barista-production-YYYY-MM-DD.geneontology.org"] - see Prerequisites 7 for exact text

dns_zone_id: should be "Z04640331A23NHVPCC784" (for geneontology.org).
```
cp ./production/config-instance.yaml.sample config-instance.yaml
emacs config-instance.yaml
```

### 5.  Test and Instantiate instance on aws
Test the deployment.  From command given below, update noctua-production-YYYY-MM-DD to actual workspace name from Prerequisites 7 and run
```
go-deploy --workspace REPLACE_ME_WITH_S3_WORKSPACE_NAME --working-directory aws -verbose -dry-run --conf config-instance.yaml
```

From command given below, update noctua-production-YYYY-MM-DD to actual workspace name from Prerequisites 7 and run
```
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose --conf config-instance.yaml
```

Optional, but useful commands
List workspaces to ensure one has been created for `noctua-production-YYYY-MM-DD`
```
go-deploy --working-directory aws -list-workspaces -verbose

# Display the terraform state
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -show

# Display the public ip address of the aws instance 
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -output

#Useful Information When Debugging.
# The deploy command creates a terraform tfvars. These variables override the variables in `aws/main.tf`
cat noctua-production-YYYY-MM-DD.tfvars.json

# The Deploy command creates a ansible inventory file.
cat noctua-production-YYYY-MM-DD-inventory.cfg
```

This can also be validated by logging into aws and viewing the s3 bucket for 'go-workspace-noctua'.  There will be an entry for `noctua-production-YYYY-MM-DD`.  Drill down and view Terraform details.  There will be a running instance of `noctua-production-YYYY-MM-DD` under EC2 instances.  Route 53 hosted instances for 'geneontology.org' will have 'A' records for both  `noctua-production-YYYY-MM-DD` and 'barista-production-YYYY-MM-DD.geneontology.org'


Now that an instance has been created, you can login into the instance with the instance name or IP address
```
ssh -i /tmp/go-ssh ubuntu@noctua-production-YYYY-MM-DD.geneontology.org
logout
```


##### 6.  Update configuration files to deploy on aws
Modify the stack configuration file as follows:
 - `USE_QOS: 0` should be `USE_QOS: 1`
 - `S3_BUCKET: REPLACE_ME` should be `S3_BUCKET: go-service-logs-noctua-production`
 - `S3_SSL_CERTS_LOCATION: s3://REPLACE_ME_CERT_BUCKET/REPLACE_ME_DOMAIN.tar.gz` should be `S3_SSL_CERTS_LOCATION: s3://go-service-lockbox/geneontology.org.tar.gz`

 Refer to Prerequisites 6 - copy Blazegraph journal file into /tmp directory and update REPLACE_ME_FILE_PATH with full complete path.  This may have to be done in a separate terminal which can run docker commands.  docker cp blazegraph-production.jnl.gz go-dev:/tmp.  In docker environment unzip file using gunzip /tmp/blazegraph-production.jnl.gz
 or retrieve file using something similar to cd /tmp && wget http://skyhook.berkeleybop.org/blazegraph-20230611.jnl
  - `BLAZEGRAPH_JOURNAL: REPLACE_ME_FILE_PATH # /tmp/blazegraph-20230611.jnl` should be `BLAZEGRAPH_JOURNAL: /tmp/blazegraph-production.jnl` 
 
 - `noctua_host: REPLACE_ME # aes-test-noctua.geneontology.io` should be `noctua_host: http://noctua.geneontology.org`

 Refer to Prerequisites 7 - Update year, month and date for current workspace.  This will be same as Workflow Step 4, first entry in 'dns_record_name'
 - `noctua_host_alias: REPLACE_ME` should be `noctua_host_alias: noctua-production-YYYY-MM-DD.geneontology.org`

 - `noctua_lookup_url: REPLACE_ME # https://golr-aux.geneontology.io/solr/` should be `noctua_lookup_url: https://golr-aux.geneontology.io/solr/`
 - `golr_neo_lookup_url: REPLACE_ME # https://aes-test-noctua.geneontology.io` should be `noctua_lookup_url: https://aes-test-noctua.geneontology.io`

 Refer to Prerequisites 3 and update the github client id and github client secret
 - `github_client_id: 'REPLACE_ME'` should be `github_client_id: 'github client id'`
 - `github_client_secret: 'REPLACE_ME'` should be `github_client_secret: 'github client secret'`
 - `github_callback_url: REPLACE_ME # https://aes-test-barista.geneontology.io/auth/github/callback` should be `github_callback_url: https://aes-test-barista.geneontology.io/auth/github/callback`

 - `golr_lookup_url: REPLACE_ME # https://aes-test-golr.geneontology.io/solr` should be  `golr_lookup_url: https://aes-test-golr.geneontology.io/solr`

 Refer to Prerequisites 7 and get barista host name. It should be something similar to go-barista-production-2024-10-02.geneontology.org
- `barista_lookup_host: REPLACE_ME # aes-test-barista.geneontology.io` should be `barista_lookup_host: aes-test-barista.geneontology.io`
- `barista_lookup_host_alias: REPLACE_ME` should be `barista_lookup_host_alias: go-barista-production-YYYY-MM-DD.geneontology.org `
- `barista_lookup_url: REPLACE_ME # https://aes-test-barista.geneontology.io` should be `barista_lookup_host: https://aes-test-barista.geneontology.io`    
```

cp ./production/config-stack.yaml.sample ./config-stack.yaml
emacs ./config-stack.yaml
```


DELETE - Dont need this as it is already specified in stack.yaml file==============================
Modify the ssl vars file as follows:
```
emacs ./ssl-vars.yaml
 - `S3_SSL_CERTS_LOCATION: s3://REPLACE_ME_CERT_BUCKET/REPLACE_ME_DOMAIN.tar.gz` should be `S3_SSL_CERTS_LOCATION: s3://go-service-lockbox/geneontology.org.tar.gz`
```
=============================



There are two sets of files that will be updated for instantiating and configuring.
1.  Files used by Terraform to instantiate instances
2.  Files used by Ansible to configure the instances

Other artifacts used by the instances.  Example Blazegraph 



### Deploy a version of the Noctua editor (including minerva, barista, noctua):
  - Important ansible files:
    - vars.yaml
    - docker-vars.yaml
    - s3-vars.yaml
    - ssl-vars.yaml
    - stage.yaml
    - qos-vars.yaml
    - start_services.yaml
  
### Artifacts Deployed To Staging directory On AWS:
  - blazegraph.jnl
  - Cloned repositories:
    - noctua-form, noctua-landing-page, noctua-models, go-site and noctua-visual-pathway-editor.
  - s3 credentials used to push apache logs to s3 buckets and to download ssl credentials from s3 bucket
  - qos.conf and robots.txt for apache mitigation
  - github OAUTH client id and secret
  - docker-production-compose and various configuration files from template directory

## Requirements
- Note, these are met via a Docker based environment where these tools are installed
- Terraform. Tested using v1.1.4
- Ansible. Tested using version 2.10.7




## S3 Terraform Backend

We use S3 terraform backend to store terraform's state. See production/backend.tf.sample

## Github OAUTH
Noctua uses OAUTH for authentication. See templates/github.yaml 

## Prepare Blazegraph journal locally

if you do not have a journal see production/gen_journal.sh.sample to generate one

## DNS 

Note: DNS records are used for noctua and barista. The tool would create them during create phase and destroy them during destroy phase. See `dns_record_name` in the instance config file, ` noctua_host` and `barista_lookup_host` in the stack config file.

The aliases `noctua_host_alias` and `barista_lookup_host_alias` should be FQDN of an EXISTING DNS record. This reccord should NOT be managed by the tool otherwise the tool would delete them during the destroy phase.

Once the instance has been provisioned and tested, this DNS record would need to be updated manually to point to the public ip address of the vm.

## Golr/Amigo
Use the dns name of the external golr instance running alongside amigo. For testing pourposes you can just use aes-test-golr.geneontology if you have deployed the amigo/golr stack or noctua-golr.berkeleybop.org if it is up and running. 

## SSH Keys
For testing purposes you can you your own ssh keys. But for production please ask for the go ssh keys.

## Prepare The AWS Credentials

The credentials are need by terraform to provision the AWS instance and are used by the provisioned instance to access the s3 bucket used as a certificate store and push aapache logs. One could also copy in from an existing credential set, see Appendix I at the end for more details.

- [ ] Copy and modify the aws credential file to the default location `/tmp/go-aws-credentials` <br/>`cp production/go-aws-credentials.sample /tmp/go-aws-credentials`
- [ ] You will need to supply an `aws_access_key_id` and `aws_secret_access_key`. These will be marked with `REPLACE_ME`.

## Prepare And Initialize The S3 Terraform Backend

The S3 backend is used to store the terraform state.

Check list:
- [ ] Assumes you have prepared the aws credentials above.
- [ ] Copy the backend sample file <br/>`cp ./production/backend.tf.sample ./aws/backend.tf`
- [ ] Make sure you have the correct s3 bucket configured in the bakend file <br/>`cat ./aws/backend.tf `
- [ ] Execute the command set right below in "Command set".

<b>Command set</b>:

```
# Use the aws cli to make sure you have access to the terraform s3 backend bucket

export AWS_SHARED_CREDENTIALS_FILE=/tmp/go-aws-credentials
aws s3 ls s3://REPLACE_ME_WITH_TERRAFORM_BACKEND_BUCKET # S3 bucket
go-deploy -init --working-directory aws -verbose
```

## Workspace Name

Use these commands to figure out the name of an existing workspace if any. The name should have a pattern `production-YYYY-MM-DD`

Check list:

- [ ] Assumes you have initialized the backend. See above
```
go-deploy --working-directory aws -list-workspaces -verbose
```

## Provision Instance on AWS

Use the terraform commands shown above to figure out the name of an existing
workspace. If such workspace exists, then you can skip the
provisionning of the aws instance. Or you can destroy the aws instance
and re-provision if that is the intent.

Check list:
- [ ] <b>Choose your workspace name. We use the following pattern `production-YYYY-MM-DD`</b>. For example: `production-2023-01-30`.
- [ ] Copy `production/config-instance.yaml.sample` to another location and modify using vim or emacs.
- [ ] Verify the location of the ssh keys for your AWS instance in your copy of `config-instance.yaml` under `ssh_keys`.
- [ ] Verify location of the public ssh key in `aws/main.tf`
- [ ] Remember you can use the -dry-run and the -verbose options to test "go-deploy"
- [ ] Execute the command set right below in "Command set".
- [ ] Note down the ip address of the aws instance that is created. This can also be found in production-YYYY-MM-DD.cfg

<b>Command set</b>:
```
cp ./production/config-instance.yaml.sample config-instance.yaml
cat ./config-instance.yaml   # Verify contents and modify as needed.

# Deploy command.
go-deploy --workspace production-YYYY-MM-DD --working-directory aws -verbose --conf config-instance.yaml

# Display the terraform state
go-deploy --workspace production-YYYY-MM-DD --working-directory aws -verbose -show

# Display the public ip address of the aws instance. 
go-deploy --workspace production-YYYY-MM-DD --working-directory aws -verbose -output

#Useful Information When Debugging.
# The deploy command creates a terraform tfvars. These variables override the variables in `aws/main.tf`
cat production-YYYY-MM-DD.tfvars.json

# The Deploy command creates a ansible inventory file.
cat production-YYYY-MM-DD-inventory.cfg
```

## Deploy Stack to AWS

Check list:
- [ ] Check that DNS names for noctua and barista map point to public ip address on AWS Route 53.
- [ ] Location of SSH keys may need to be replaced after copying config-stack.yaml.sample
- [ ] Github credentials will need to be replaced in config-stack.yaml.sample
- [ ] s3 credentials are placed in a file using format described above
- [ ] s3 uri if ssl is enabled. Location of ssl certs/key
- [ ] qos mitigation if qos is enabled
- [ ] Location of blazegraph.jnl. This assumes you have generated the journal using steps above
- [ ] Use same workspace name as in previous step
- [ ] Remember you can use the -dry-run and the -verbose options
- [ ] Optional When Testing: change dns names in the config file for noctua, barista, and golr. 
- [ ] Execute the command set right below in "Command set".

<b>Command set</b>:

```
cp ./production/config-stack.yaml.sample ./config-stack.yaml
cat ./config-stack.yaml    # Verify contents and modify if needed.
export ANSIBLE_HOST_KEY_CHECKING=False
go-deploy --workspace production-YYYY-MM-DD --working-directory aws -verbose --conf config-stack.yaml
```

## Access noctua from a browser

Check list:
- [ ] noctua is up and healthy. We use health checks in docker compose file
- [ ] Use noctua dns name. http://{noctua_host} or https://{noctua_host} if ssl is enabled. 

## Debugging

- ssh to machine. username is ubuntu. Try using dns names to make sure they are fine
- docker-compose -f stage_dir/docker-compose.yaml ps
- docker-compose -f stage_dir/docker-compose.yaml down # whenever you make any changes 
- docker-compose -f stage_dir/docker-compose.yaml up -d
- docker-compose -f stage_dir/docker-compose.yaml logs -f 
- Use -dry-run and copy and paste the command and execute it manually

## Destroy Instance and Delete Workspace.

```sh
Make sure you are deleting the correct workspace.
go-deploy --workspace production-YYYY-MM-DD --working-directory aws -verbose -show

# Destroy.
go-deploy --workspace production-YYYY-MM-DD --working-directory aws -verbose -destroy
```

## Appendix I: Development Environment

```
# Start docker container `go-dev` in interactive mode.
docker run --rm --name go-dev -it geneontology/go-devops-base:tools-jammy-0.4.2  /bin/bash

# In the command above we used the `--rm` option which means the container will be deleted when you exit. If that is not
# the intent and you want delete it later at your own convenience. Use the following `docker run` command.

docker run --name go-dev -it geneontology/go-devops-base:tools-jammy-0.4.2  /bin/bash

# Exit or stop the container.
docker stop go-dev  # stop container with the intent of restarting it. This equivalent to `exit` inside the container

docker start -ia go-dev  # restart and attach to the container
docker rm -f go-dev # get rid of it for good when ready.
```

SSH/AWS Credentials:

Use `docker cp` to copy these credentials to /tmp. You can also copy and paste using your favorite editor vim or emacs.

Under /tmp you would need the following:

- /tmp/go-aws-credentials
- /tmp/go-ssh
- /tmp/go-ssh.pub

```
# Example using `docker cp` to copy files from host to docker container named `go-dev`

docker cp <path_on_host> go-dev:/tmp/
```

Then, within the docker image:

```
chown root /tmp/go-*
chgrp root /tmp/go-*
```

