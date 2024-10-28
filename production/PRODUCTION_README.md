# Noctua Production Deployment


This repository enables the deployment of the noctua stack to AWS. It includes minerva, barista, and noctua and it points to an external amigo instance. The architecture is designed so that sub-components can easily be provisioned, instantiated and deployed. When it is time for the system to be destroyed, all subsystems and artifacts should be removed.    


 ## Conventions
 Creating and deploying instances on aws involves the creation of multiple artifacts in Route53, EC2, S3...  In order to easily identify all artifacts associated with a workspace instance, a naming convention is utilized.  This allows for easy deletion when a workspace needs to be taken down.   Geneontology dev-ops follows a namespace pattern for workspaces. it is `go-workspace-_______`.  For noctua, it is `go-workspace-noctua`.  Similarly, for the workspace instance, it is namespace pattern `_____-production-YYYY-MM-DD`; e.g.: `graphstore-production-2024-08-26` or `go-api-production-2023-01-30`.  For noctua, it will be `noctua-production-YYYY-MM-DD` or `___-noctua-test-YYYY-MM-DD` where `___` should be replaced with yourr initials.  The details about the workspace instance will be stored in the S3 buckets under `go-workspace-noctua`.
 An instance is created on EC2.  The instance name and workspace names are the same.
 
Login into aws and view the S3 buckets information.  Drill down by selecting 'go-workspace-graphstore'->'env:/'->'production-YYYY-MM-DD'->graphstore->terraform.tfstate.  The Terraform state information can be downloaded.  Specific EC2 instance information details can be viewed by selecting EC2 then clicking on instances and searching for entries with names containing 'production'. There should be an entry for `graphstore-production-YYYY-MM-DD`.  DNS information will be under Route 53.  The hosted zones section will have an entry for `geneontology.org` and `geneontology.io`.  For production, we use domain `.org` and for testing we use domain `.io`


## Prerequisites 
Before starting, ensure the following are available
1.  aws credentials (aws_access_key_id and aws_secret_access_key)

2.  SSH keys in the shared SpderOak store

3.  github_client_id and github_client_secret  - Github OAuth 

4.  Local instance of Docker.  Docker commands are executed from a terminal window or Windows command prompt

5.  Blazegraph journal file.  production/gen_journal.sh has instructions on creating one.  Or Download from http://current.geneontology.org/products/blazegraph/blazegraph-production.jnl.gz.

6.  Determine the workspace namespace pattern.  If this is for testing purposes, the workspace name should have your initials and the label 'test' as part of its name. For example, for testing, aes-noctua-test-2024-10-02 or for production,  noctua-production-2024-10-02.  Since, the namespace will be used multiple times, to make things easier, and more imporatantly, to prevent creating actual instances with labels containing `YYYYY-MM-DD`, open up a text editor and enter the namespace.

 In addition to noctua, other instances and artifacts will also be created.  These should also follow the namespace pattern:
|Item    | Artifact           |  production                                               | test                                                  |
|----    | -------            | ------------------------------------------------          | ------------------------------------------------------|
|6a      | noctua bucket      | go-workspace-noctua                                       | go-workspace-noctua                                   |
|6b      | certificate url    | s3://go-service-lockbox/geneontology.orrg.tar.gz          | s3://go-service-lockbox/geneontology.io.tar.gz        |
|6c      | workspace name     | noctua-production-YYYY-MM-DD                              | ___-noctua-test-YYYY-MM-DD                            |
|6d      | noctua             | noctua-production-YYYY-MM-DD.geneontology.org             | ___-noctua-test-YYYY-MM-DD.geneontology.io            |
|6e      | barista            | barista-production-YYYY-MM-DD.geneontology.org            | ___-barista-test-YYYY-MM-DD.geneontology.io           |
|6f      | current noctua url | http://noctua.geneontology.org                            | http://noctua.geneontology.io                         |
|6g      | noctua/golr lookup | https://golr-aux.geneontology.org/solr/                   | https://golr-aux.geneontology.io/solr/                |
|6h      | barista url        | barista-production-YYYY-MM-DD.geneontology.org            | https://___-barista-test-YYYY-MM-DD.geneontology.io   |
 
Both production and testing will execute a command to initialize the workspace:
go-deploy -init --working-directory aws -verbose 
 
The workspace name will be used to instantiate, deploy and destroy.  The 3 commands are as follows:

For production
- go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose --conf config-instance.yaml

- go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose --conf config-stack.yaml

- go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -destroy

The instantiate and deploy commands can be tested before instantiation with the 'dry-run' option:  

- go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -dry-run  --conf config-stack.yaml
   
The instance name of the server will be noctua-production-YYYY-MM-DD.geneontology.org

A barista instance will be created on go-barista-production-YYYY-MM-DD.geneontology.org


For testing
- go-deploy --workspace ___-noctua-test-YYYY-MM-DD --working-directory aws -verbose --conf config-instance.yaml

- go-deploy --workspace ___-noctua-test-YYYY-MM-DD --working-directory aws -verbose --conf config-stack.yaml

- go-deploy --workspace ___-noctua-test-YYYY-MM-DD --working-directory aws -verbose -destroy

The deploy command can be tested before instantiation with the 'dry-run' option:  

- go-deploy --workspace ___-noctua-test--YYYY-MM-DD --working-directory aws -verbose -dry-run  --conf config-stack.yaml

   
The instance name of the server will be ___-noctua-test-YYYY-MM-DD.geneontology.io

A barista instance will be created on ___-barista-test-YYYY-MM-DD.geneontology.io


Copy the above commands into a text editor and update the workspace names.     

  


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
We have a docker based dev environment with all these tools installed. See last section of this README (Appendix I: Development Environment).
See Prerequisites 4 for docker 
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

### 3.  Add an entry in the aws s3 for storing information about the workspace instance and initialize
Update entry for bucket  = `REPLACE_ME_NOCTUA_TERRAFORM_BUCKET` to "go-workspace-noctua" (Item 6a)
```
cp ./production/backend.tf.sample ./aws/backend.tf
emacs ./aws/backend.tf
```

Initialize working directory for workspace and list workspace buckets
```
go-deploy -init --working-directory aws -verbose
go-deploy --working-directory aws -list-workspaces -verbose
```


### 4. Update configuration file to instantiate instance on aws

Name: REPLACE_ME should be `noctua-production-YYYY-MM-DD` or `___-noctua-test-YYYY-MM--DD` - see Prerequisites 6 (Item 6c) for exact text

dns_record_name: should be `["noctua-production-YYYY-MM-DD.geneontology.org", "barista-production-YYYY-MM-DD.geneontology.org"]` or `["___-noctua-test-YYYY-MM-DD.geneontology.io", "___-barista-test-YYYY-MM-DD.geneontology.io"]` - see Prerequisites 6 (Item 6d, 6e) for exact text

dns_zone_id: should be `Z04640331A23NHVPCC784` for geneontology.org (productio) or `Z1SMAYFNVK75BZ` for geneontology.io (testing) 

```
cp ./production/config-instance.yaml.sample config-instance.yaml
emacs config-instance.yaml
```

### 5.  Test and Instantiate instance on aws
Test the deployment.  From command given below, update REPLACE_ME_WITH_S3_WORKSPACE_NAME to something of the form `noctua-production-YYYY-MM-DD` to match actual workspace name from Prerequisites 6 (Item 6c) and run

```
go-deploy --workspace REPLACE_ME_WITH_S3_WORKSPACE_NAME --working-directory aws -verbose -dry-run --conf config-instance.yaml
```

From command given below, update REPLACE_ME_WITH_S3_WORKSPACE_NAME to something of the form `noctua-production-YYYY-MM-DD` to match actual workspace name from Prerequisites 6 and run
```
go-deploy --workspace REPLACE_ME_WITH_S3_WORKSPACE_NAME --working-directory aws -verbose --conf config-instance.yaml
```

Note, IP address of the EC2 instance.  

Optional, but useful commands
List workspaces to ensure one has been created
```
go-deploy --working-directory aws -list-workspaces -verbose

# Display the terraform state. Replace as specified in Prerequisites 6 (Item 6c)
go-deploy --workspace REPLACE_ME_WITH_S3_WORKSPACE_NAME --working-directory aws -verbose -show

# Display the public ip address of the aws instance.  Update command as specified in Prerequisites 6 (Item 6c)
go-deploy --workspace REPLACE_ME_WITH_S3_WORKSPACE_NAME --working-directory aws -verbose -output

#Useful Information When Debugging. Replace as specified in Prerequisites 6 (Item 6c)
# The deploy command creates a terraform tfvars. These variables override the variables in `aws/main.tf`
cat REPLACE_ME_WITH_S3_WORKSPACE_NAME.tfvars.json

# The Deploy command creates a ansible inventory file. Replace as specified in Prerequisites 6 (Item 6c)
cat REPLACE_ME_WITH_S3_WORKSPACE_NAME-inventory.cfg
```

This can also be validated by logging into aws and viewing the s3 bucket for 'go-workspace-noctua'.  There will be an entry for the workspace instance name.  Drill down and view Terraform details.  There will be a running instance under EC2 instances.  Route 53 hosted instances for 'geneontology.org' or 'geneontology.io' will have 'A' records for both  noctua and barista


Now that an instance has been created, you can login into the instance with the instance name or IP address.  Replace host name as specified in Prerequisites 6 (Item 6d)
```
ssh -i /tmp/go-ssh ubuntu@noctua-production-YYYY-MM-DD.geneontology.org or ssh -i /tmp/go-ssh ubuntu@ ___-noctua-test-YYYY-MM-DD.geneontology.io 
logout
```


### 6.  Update configuration files to deploy on aws
Modify the stack configuration file as follows:
 - `S3_BUCKET: REPLACE_ME_APACHE_LOG__BUCKET` This should be `S3_BUCKET: go-service-logs-noctua-production` for production or `S3_BUCKET: go-service-logs-noctua-test` for test instance
 - `USE_QOS: 0` should be `USE_QOS: 1`
 - `S3_SSL_CERTS_LOCATION: s3://REPLACE_ME_CERT_BUCKET/REPLACE_ME_DOMAIN.tar.gz` should be `S3_SSL_CERTS_LOCATION: s3://go-service-lockbox/geneontology.org.tar.gz` for production or `S3_SSL_CERTS_LOCATION: s3://go-service-lockbox/geneontology.io.tar.gz` for test instance.  Replace as specified in Prerequisites 6 (Item 6b)

 Refer to Prerequisites 5 - copy Blazegraph journal file into /tmp directory and update REPLACE_ME_FILE_PATH with full complete path.  This may have to be done in a separate terminal which can run docker commands.  docker cp blazegraph-production.jnl.gz go-dev:/tmp.  In docker environment unzip file using gunzip /tmp/blazegraph-production.jnl.gz
 or retrieve file using something similar to cd /tmp && wget http://skyhook.berkeleybop.org/blazegraph-20230611.jnl
  - `BLAZEGRAPH_JOURNAL: REPLACE_ME_FILE_PATH # /tmp/blazegraph-20230611.jnl` should be `BLAZEGRAPH_JOURNAL: /tmp/blazegraph-production.jnl` 
 
 - `noctua_host: REPLACE_ME # noctua.geneontology.org or noctua.geneontology.io For production, update to current production system `noctua_host: http://noctua.geneontology.org` or `noctua_host: http://noctua.geneontology.io` for testing. Replace as specified in Prerequisites 6 (Item 6f)

 Refer to Prerequisites 6  Replace as specified in Prerequisites 6 (Item 6c)- Update year, month and date for current workspace.  This is also same as Workflow Step 4, 'dns_record_name'
 - `noctua_host_alias: REPLACE_ME` should be `noctua_host_alias: noctua-production-YYYY-MM-DD.geneontology.org` or  `noctua_host_alias: ___-noctua-test-YYYY-MM-DD.geneontology.io`

 - `noctua_lookup_url: REPLACE_ME # https://noctua-production-2024-10-15.geneontology.org or https://aes-noctua-test-2024-10-15.geneontology.io` For production, should be `noctua_lookup_url: noctua-production-YYYY-MM-DD.geneontology.org` or for testing, `noctua_lookup_url:  ___-noctua-test-YYYY-MM-DD.geneontology.io`.  Refer to Prerequisites 6  Replace as specified in Prerequisites 6 (Item 6d)
 - `golr_neo_lookup_url: REPLACE_ME # https://golr-aux.geneontology.org/solr/ or https://golr-aux.geneontology.io/solr/` For production, should be `golr_neo_lookup_url: https://golr-aux.geneontology.org/solr/` or for testing, `golr_neo_lookup_url: https://golr-aux.geneontology.io/solr/`.  Refer to Prerequisites 6  Replace as specified in Prerequisites 6 (Item 6g) 

 Refer to Prerequisites 3 and update the github client id and github client secret
 - `github_client_id: 'REPLACE_ME' should be `github_client_id: 'github client id'`
 - `github_client_secret: 'REPLACE_ME'` should be `github_client_secret: 'github client secret'`

 Refer to Prerequisites 3 and 6 (Item 6e) - Update year, month and date for current workspace for barista instance
 - `github_callback_url: REPLACE_ME # barista-production-2024-10-15.geneontology.org/auth/github/callback or https://aes-barista-test-2024-10-15.geneontology.io/auth/github/callback`. For production, update to `github_callback_url: barista-production-YYYY-MM-DD.geneontology.org/auth/github/callback` or for testing, `github_callback_url: ___-barista-test-YYYY-MM-DD.geneontology.io/auth/github/callback`

Refer to Prerequisites 6 Replace as specified in Prerequisites 6 (Item 6g)- Update year, month and date for current workspace for golr instance
 - `golr_lookup_url: REPLACE_ME #  https://golr-aux.geneontology.org/solr/ or https://golr-aux.geneontology.io/solr/`. For production, should be  `golr_lookup_url: https://golr-production-YYYY-MM-DD.geneontology.org/solr` or for testing, `golr_lookup_url: https://___-golr-test-YYYY-MM--DD.geneontology.io/solr`

 Refer to Prerequisites 6 - Update year, month and date for current workspace for barista instance
- `barista_lookup_host: REPLACE_ME # barista-production-2024-10-15.geneontology.org or aes-barista-test-2024-10-15.geneontology.io`. For production, should be `barista_lookup_host: barista-production-YYYY-MM-DD.geneontology.org` or for testing, `barista_lookup_host:  ___-barista-test-YYYY-MM-DD.geneontology.io`. Refer to Prerequisites 6  Replace as specified in Prerequisites 6 (Item 6e)
- `barista_lookup_host_alias: REPLACE_ME barista-production-2024-10-15.geneontology.org or am-barista-test-2024-10-15.geneontology.io`. For production, should be `barista_lookup_host_alias: barista-production-YYYY-MM-DD.geneontology.org` or for testing, `barista_lookup_host_alias: ___-barista-test-YYYY-MM-DD.geneontology.io`. Refer to Prerequisites 6  Replace as specified in Prerequisites 6 (Item 6e)
- `barista_lookup_url: REPLACE_ME #  https://barista-production-2024-10-15.geneontology.org or https://am-barista-test-2024-10-15.geneontology.io` For production, should be `barista_lookup_url: https://barista-production-YYYY-MM-DD.geneontology.org` or for testing, `barista_lookup_url: https://___-barista-test-YYYY-MM-DD.geneontology.io`. Refer to Prerequisites 6  Replace as specified in Prerequisites 6 (Item 6h)

```
cp ./production/config-stack.yaml.sample ./config-stack.yaml
emacs ./config-stack.yaml
```



### 7.  Deploy
Update workspace name in command below. Refer to Prerequisites 6 (Item 6c) and run

```
go-deploy --workspace REPLACE_ME_WITH_S3_WORKSPACE_NAME --working-directory aws -verbose --conf config-instance.yaml
If the system prompts, reply yes:
The authenticity of host 'xxx.xxx.xxx.xxx (xxx.xxx.xxx.xx)' can't be established.
ED25519 key fingerprint is SHA256:------------------------.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```











=====================================================================================================




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

