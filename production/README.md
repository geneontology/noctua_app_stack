# Noctua Production Deployment

This repository enables the deployment of the Noctua stack to AWS. It
includes minerva, barista, and noctua, which points to an external
amigo instance. The architecture is designed so that sub-components
can easily be provisioned, instantiated and deployed. When it is time
for the system to be destroyed, all subsystems and artifacts should be
removed.

## Prerequisites

Before starting, ensure the following are available:

1. AWS credentials (`aws_access_key_id` and `aws_secret_access_key`).
2. SSH keys - Refer to on-boarding instructions.
3. `github_client_id` and `github_client_secret` - Github OAuth; these
   should be clarified or made in GitHub's Org -> Settings ->
   Developer settings -> OAuth Apps.
4. Docker. Docker commands are executed from a terminal window or
   Windows command prompt
5. Blazegraph journal file. `production/gen_journal.sh` has
   instructions on creating one. One may also download a test journal
   from a release
   (e.g. http://current.geneontology.org/products/blazegraph/blazegraph-production.jnl.gz)
   or use the outage instructions to create a journal.
6. Determine your environment: "production" (which will be deployed to
   geneontology.org) or "development" (which will be deployed to
   geneontology.io).
7. Determine the workspace namespace pattern; basically, whenever you
   see `YYYY-MM-DD`, choose today's date (e.g. 2025-03-16). This will
   uniquely identify this server now and in the future.

## Create a Docker development environment and clone repository from Github

We have a docker based dev environment with all these tools installed.

```bash
docker rm noctua-devops || true
docker run --name noctua-devops -it geneontology/go-devops-base:tools-jammy-0.4.4  /bin/bash
cd /tmp && git clone https://github.com/geneontology/noctua_app_stack.git && cd noctua_app_stack
```

Test with:

```bash
go-deploy -h
```

## Add credentials for accessing and provisioning resources on AWS

### On host machine

Copy the ssh keys from your docker host into the running docker image, in `/tmp`:

```bash
docker cp go-ssh noctua-devops:/tmp
docker cp go-ssh.pub noctua-devops:/tmp
```

### In docker image

You should now have the following in your image:

```bash
ls -latr /tmp/go-ssh*
/tmp/go-ssh
/tmp/go-ssh.pub
```

Make sure they have the right permissions to be used:

```bash
chmod 600 /tmp/go-ssh*
```

Within the running image, copy and modify the AWS credential file to
the default location `/tmp/go-aws-credentials`.

```bash
cp production/go-aws-credentials.sample /tmp/go-aws-credentials
emacs /tmp/go-aws-credentials
```

Replace the `REPLACE_ME`s for  `aws_access_key_id` and `aws_secret_access_key` with your personal dev keys into the file.

Now export into your running docker environment.

```bash
export AWS_SHARED_CREDENTIALS_FILE=/tmp/go-aws-credentials
```

## Add an entry in the AWS S3 for storing information about the workspace instance and initialize

```bash
cp ./production/backend.tf.sample ./aws/backend.tf
emacs ./aws/backend.tf
```

Update entry for bucket `REPLACE_ME_NOCTUA_TERRAFORM_BUCKET` to
"go-workspace-noctua".

Initialize working directory for workspace and list workspace buckets:

```bash
go-deploy -init --working-directory aws -verbose
```

Test with:

```bash
go-deploy --working-directory aws -list-workspaces -verbose
```

### 4. Update configuration file to instantiate instance on AWS

```bash
cp ./production/config-instance.yaml.sample config-instance.yaml
emacs config-instance.yaml
```

Converting `YYYY-MM-DD` to today's date, uncomment the `Name`,
`dns_record_name`, and `dns_zone_id` as appropriate.

## Test and instantiate instance on AWS

For production:

```bash
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -dry-run --conf config-instance.yaml
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose --conf config-instance.yaml
```

For development:

```bash
go-deploy --workspace noctua-development-YYYY-MM-DD --working-directory aws -verbose -dry-run --conf config-instance.yaml
go-deploy --workspace noctua-development-YYYY-MM-DD --working-directory aws -verbose --conf config-instance.yaml
```

Note the IP address of the EC2 instance.

### Optional, but useful, commands at this point

List workspaces to ensure one has been created:

```bash
go-deploy --working-directory aws -list-workspaces -verbose
```

Display the terraform state, then display the IP address.

The deploy command creates a terraform tfvars. These variables
override the variables in `aws/main.tf` As well, the deploy command
creates a ansible inventory file.

For production:

```bash
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -show
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -output
cat noctua-development-YYYY-MM-DD.tfvars.json
cat noctua-development-YYYY-MM-DD-inventory.cfg
```

For development:

```bash
go-deploy --workspace noctua-development-YYYY-MM-DD --working-directory aws -verbose -show
go-deploy --workspace noctua-development-YYYY-MM-DD --working-directory aws -verbose -output
cat noctua-development-YYYY-MM-DD.tfvars.json
cat noctua-development-YYYY-MM-DD-inventory.cfg
```

All this can also be validated by logging into AWS and viewing the S3
bucket for 'go-workspace-noctua'. There will be an entry for the
workspace instance name. Drill down and view Terraform details. There
will be a running instance under EC2 instances. Route 53 hosted
instances for 'geneontology.org' or 'geneontology.io' will have 'A'
records for both noctua and barista.

Now that an instance has been created, you should login into the
instance with the instance name or IP address.

```bash
ssh -i /tmp/go-ssh ubuntu@noctua-production-YYYY-MM-DD.geneontology.org
ssh -i /tmp/go-ssh ubuntu@noctua-development-YYYY-MM-DD.geneontology.io
```

## Update configuration files for stack deployment on AWS

```bash
cp ./production/config-stack.yaml.sample ./config-stack.yaml
emacs ./config-stack.yaml
```

Modify the stack configuration file as follows:

- `S3_BUCKET: REPLACE_ME_APACHE_LOG_BUCKET` This should be `S3_BUCKET: go-service-logs-noctua-production` for production or `S3_BUCKET: go-service-logs-noctua-development` for development.
- `S3_SSL_CERTS_LOCATION: REPLACE_ME_CERT_LOCATION` should be `S3_SSL_CERTS_LOCATION: s3://go-service-lockbox/geneontology.org.tar.gz` for production or `S3_SSL_CERTS_LOCATION: s3://go-service-lockbox/geneontology.io.tar.gz` for development.
- `BLAZEGRAPH_JOURNAL: REPLACE_ME_FILE_PATH` should be the full path to your blazegraph (see prereqs "5"). This may have to be done in a separate terminal which can run docker commands. E.g.: `docker cp blazegraph.jnl noctua-devops:/tmp/blazegraph-2025-04-11.jnl`. Make sure the file is unzipped in the docker image.
- `golr_neo_lookup_url: https://golr-aux.geneontology.org/solr/` For production, should be `golr_neo_lookup_url: https://noctua-golr.berkeleybop.org/`; for development, you will likely use the instance of AmiGO/GOlr loaded with NEO (see above) that you stood up; the URL would be like: `golr_neo_lookup_url: https://golr-development-2025-04-11.geneontology.io/solr/`.
- `github_client_id: 'REPLACE_ME'` should be "github client id"
- `github_client_secret: 'REPLACE_ME'` should be "github client secret"
- `github_callback_url` should be uncommented and updated
- `barista_lookup_host` should be uncommented and updated
- `barista_lookup_host_alias` should be uncommented and updated
- `barista_lookup_url` should be uncommented and updated

## Deploy

Test the deployment with the `dry-run` parameter.

```
go-deploy --workspace REPLACE_ME_WITH_S3_WORKSPACE_NAME --working-directory aws -verbose -dry-run --conf config-stack.yaml
```

Update workspace name in command below. Refer to Prerequisites 6 (Item 6c) and run

```
go-deploy --workspace REPLACE_ME_WITH_S3_WORKSPACE_NAME --working-directory aws -verbose --conf config-stack.yaml
If the system prompts, reply yes:
The authenticity of host 'xxx.xxx.xxx.xxx (xxx.xxx.xxx.xx)' can't be established.
ED25519 key fingerprint is SHA256:------------------------.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```

REMEMBER: it may take a while to fully spin up, even after it
returns. (5-10m?)

# Destroy Instance and Delete Workspace.

```sh
Make sure you are deleting the correct workspace. Refer to Prerequisites 6 (Item 6c) and run
go-deploy --workspace REPLACE_ME_WITH_S3_WORKSPACE_NAME --working-directory aws -verbose -show

# Destroy. Refer to Prerequisites 6 (Item 6c) and run
go-deploy --workspace REPLACE_ME_WITH_S3_WORKSPACE_NAME --working-directory aws -verbose -destroy
```

## Additional information

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
- S3 credentials used to push apache logs to S3 buckets and to download ssl credentials from S3 bucket
- qos.conf and robots.txt for apache mitigation
- github OAuth client id and secret
- docker-production-compose and various configuration files from template directory


### Environment

- Note, these are met via a Docker based environment where these tools are installed
- Terraform. Tested using v1.1.4
- Ansible. Tested using version 2.10.7

### S3 Terraform Backend

We use S3 terraform backend to store terraform's state. See production/backend.tf.sample

### Github OAUTH

Noctua uses OAUTH for authentication. See templates/github.yaml

### Prepare Blazegraph journal locally

Ff you do not have a journal see production/gen_journal.sh.sample to generate one

### DNS

Note: DNS records are used for noctua and barista. The tool would create them during create phase and destroy them during destroy phase. See `dns_record_name` in the instance config file, ` noctua_host` and `barista_lookup_host` in the stack config file.

The aliases `noctua_host_alias` and `barista_lookup_host_alias` should be FQDN of an EXISTING DNS record. This reccord should NOT be managed by the tool otherwise the tool would delete them during the destroy phase.

Once the instance has been provisioned and tested, this DNS record would need to be updated manually to point to the public ip address of the vm.

### GOlr/AmiGO

Use the dns name of the external golr instance running alongside amigo. For testing pourposes you can just use aes-test-golr.geneontology if you have deployed the amigo/golr stack or noctua-golr.berkeleybop.org if it is up and running.

### SSH Keys

For testing purposes you can you your own ssh keys. But for production please ask for the go ssh keys.

### Prepare The AWS Credentials

The credentials are need by terraform to provision the AWS instance and are used by the provisioned instance to access the S3 bucket used as a certificate store and push aapache logs. One could also copy in from an existing credential set, see Appendix I at the end for more details.

- [ ] Copy and modify the AWS credential file to the default location `/tmp/go-aws-credentials` <br/>`cp production/go-aws-credentials.sample /tmp/go-aws-credentials`
- [ ] You will need to supply an `aws_access_key_id` and `aws_secret_access_key`. These will be marked with `REPLACE_ME`.

### Prepare And Initialize The S3 Terraform Backend

The S3 backend is used to store the terraform state.

Check list:

- [ ] Assumes you have prepared the AWS credentials above.
- [ ] Copy the backend sample file <br/>`cp ./production/backend.tf.sample ./aws/backend.tf`
- [ ] Make sure you have the correct S3 bucket configured in the bakend file <br/>`cat ./aws/backend.tf `
- [ ] Execute the command set right below in "Command set".

<b>Command set</b>:

```
# Use the AWS CLI to make sure you have access to the terraform S3 backend bucket

export AWS_SHARED_CREDENTIALS_FILE=/tmp/go-aws-credentials
aws s3 ls s3://REPLACE_ME_WITH_TERRAFORM_BACKEND_BUCKET # S3 bucket
go-deploy -init --working-directory aws -verbose
```

### Workspace Name

Use these commands to figure out the name of an existing workspace if any. The name should have a pattern `production-YYYY-MM-DD`

Check list:

- [ ] Assumes you have initialized the backend. See above

```
go-deploy --working-directory aws -list-workspaces -verbose
```

### Provision Instance on AWS

Use the terraform commands shown above to figure out the name of an existing
workspace. If such workspace exists, then you can skip the
provisionning of the AWS instance. Or you can destroy the AWS instance
and re-provision if that is the intent.

Check list:

- [ ] <b>Choose your workspace name. We use the following pattern `noctua-production-YYYY-MM-DD`</b>. For example: `noctua-production-2023-01-30`.
- [ ] Copy `production/config-instance.yaml.sample` to another location and modify using vim or emacs.
- [ ] Verify the location of the ssh keys for your AWS instance in your copy of `config-instance.yaml` under `ssh_keys`.
- [ ] Verify location of the public ssh key in `aws/main.tf`
- [ ] Remember you can use the -dry-run and the -verbose options to test "go-deploy"
- [ ] Execute the command set right below in "Command set".
- [ ] Note down the ip address of the AWS instance that is created. This can also be found in noctua-production-YYYY-MM-DD.cfg

<b>Command set</b>:

```
cp ./production/config-instance.yaml.sample config-instance.yaml
cat ./config-instance.yaml   # Verify contents and modify as needed.
```

### Deploy command.

```
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose --conf config-instance.yaml
```

### Display the terraform state

```
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -show
```

### Display the public ip address of the AWS instance.

```
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -output
```

### Useful Information When Debugging.

The deploy command creates a terraform tfvars. These variables override the variables in `aws/main.tf`
```
cat noctua-production-YYYY-MM-DD.tfvars.json
```

### The Deploy command creates a ansible inventory file.

```
cat noctua-production-YYYY-MM-DD-inventory.cfg
```

### Deploy Stack to AWS

Check list:
- [ ] Check that DNS names for noctua and barista map point to public ip address on AWS Route 53.
- [ ] Location of SSH keys may need to be replaced after copying config-stack.yaml.sample
- [ ] Github credentials will need to be replaced in config-stack.yaml.sample
- [ ] S3 credentials are placed in a file using format described above
- [ ] S3 uri if ssl is enabled. Location of ssl certs/key
- [ ] QoS mitigation if QoS is enabled
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
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose --conf config-stack.yaml
```

### Access noctua from a browser

Check list:

- [ ] noctua is up and healthy. We use health checks in docker compose file
- [ ] Use noctua dns name. http://{noctua_host} or https://{noctua_host} if ssl is enabled.

### Debugging

- ssh to machine. username is ubuntu. Try using dns names to make sure they are fine
- docker-compose -f stage_dir/docker-compose.yaml ps
- docker-compose -f stage_dir/docker-compose.yaml down # whenever you make any changes
- docker-compose -f stage_dir/docker-compose.yaml up -d
- docker-compose -f stage_dir/docker-compose.yaml logs -f
- Use -dry-run and copy and paste the command and execute it manually

### Destroy Instance and Delete Workspace.

```sh
Make sure you are deleting the correct workspace.
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -show

# Destroy.
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -destroy
```

## Appendix I: Development Environment

```
# Start docker container `noctua-devops` in interactive mode.
docker run --rm --name noctua-devops -it geneontology/go-devops-base:tools-jammy-0.4.4 /bin/bash

# In the command above we used the `--rm` option which means the container will be deleted when you exit. If that is not
# the intent and you want delete it later at your own convenience. Use the following `docker run` command.

docker run --name noctua-devops -it geneontology/go-devops-base:tools-jammy-0.4.4 /bin/bash

# Exit or stop the container.
docker stop noctua-devops  # stop container with the intent of restarting it. This equivalent to `exit` inside the container

docker start -ia noctua-devops  # restart and attach to the container
docker rm -f noctua-devops # get rid of it for good when ready.
```

SSH/AWS Credentials:

Use `docker cp` to copy these credentials to /tmp. You can also copy and paste using your favorite editor vim or emacs.

Under /tmp you would need the following:

- /tmp/go-aws-credentials
- /tmp/go-ssh
- /tmp/go-ssh.pub

```
# Example using `docker cp` to copy files from host to docker container named `noctua-devops`

docker cp <path_on_host> noctua-devops:/tmp/
```

Then, within the docker image:

```
chown root /tmp/go-*
chgrp root /tmp/go-*
```

## Appendix II: Updating software and integrating changes to the workbenches

The versions of minerva and noctua for the application stack are based on what is specified in docker-vars.yaml. If there are updates that can be released to production, then a build has to be created with the changes and pushed to the Docker Hub Container Image Library. The version number for minerva can be updated via minerva_tag and noctua version can be updated via noctua_tag.

Before operating with docker, you may need to login with
password/token:

```
docker login
```

If the operations seem odd: yes, we are grabbing these repos and building the
docker images in the root of `noctua_app_stack`.

### Build Noctua

Grab and build:
```
git checkout https://github.com/geneontology/noctua.git
docker build -f docker/Dockerfile.noctua -t 'geneontology/noctua:v6' -t 'geneontology/noctua:latest' noctua
```

Ensure the build works:
```
docker run --name mv6 -it geneontology/noctua:v6 /bin/bash
exit
```

Push to Dockerhub:
```
docker push geneontology/noctua:v6
docker push geneontology/noctua:latest
```

### Updating workbenches and configurations

To update a workbench (add/remove repo or branch), start by editing
the `staged_repos` variable in `vars.yaml` in the root directory.

You will then need to edit `templates/startup.yaml` (referenced in
`docker/Dockerfile.noctua`) to reflect this set and
layout. Specifically, the `WORKBENCHES` variable.

### Build Minerva

For example, if we're moving the docker image from Minerva v6 to
Minerva v7.


```
git checkout https://github.com/geneontology/minerva.git
docker build -f docker/Dockerfile.minerva -t 'geneontology/minerva:v7' -t 'geneontology/minerva:latest' minerva
```

Ensure the build works:
```
docker run --name mv7 -it geneontology/minerva:v7 /bin/bash
exit
```

Push to dockerhub:
```
docker push geneontology/minerva:v7
docker push geneontology/minerva:latest
```
