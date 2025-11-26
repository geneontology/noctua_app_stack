# Noctua Production Deployment

This repository documents the deployment of the Noctua stack to
AWS. It includes minerva, barista, and noctua (which points to an
external AmiGO instance, documented elsewhere). The architecture is
designed so that sub-components can easily be provisioned,
instantiated, and deployed. When it is time for the system to be
destroyed, all subsystems and artifacts will be removed.

## Prerequisites

Before starting, ensure the following are available:

1. AWS credentials (`aws_access_key_id` and `aws_secret_access_key`).
2. SSH keys. These are `go-ssh` and `go-ssh.pub`. Refer to on-boarding
   instructions.
3. The ability to get `github_client_id` and `github_client_secret` - Github OAuth; these
   should be clarified or made in GitHub's Org -> Settings ->
   Developer settings -> OAuth Apps. This will be defined later in the README.
4. Docker. Docker commands are executed from a terminal window.
5. Blazegraph journal file. `production/gen_journal.sh` has
   instructions on creating one. One may also download a test journal
   from a release
   (e.g. http://current.geneontology.org/products/blazegraph/blazegraph-production.jnl.gz)
   or use the outage instructions to create a journal. This will be defined during the README.
6. Determine your environment: "production" (which will be deployed to
   geneontology.org) or "development" (which will be deployed to
   geneontology.io).
7. Determine the workspace namespace pattern. Basically, whenever you
   see `YYYY-MM-DD` in this documentation, choose today's date
   (e.g. 2025-03-16). This will uniquely identify the workspace and
   server names.
8. An AmiGO/GOlr server with a "NEO" load. See:
   https://github.com/geneontology/amigo/blob/master/provision/production/README.md
   for setting up this instance. Collect location information for this
   server. Note that we can lso just use whatever is available, like "production" NEO for testing.

## Create a Docker development environment and clone repository from Github

We have a docker based dev environment with all these tools installed.

```bash
docker rm noctua-devops || true
docker run --name noctua-devops -it geneontology/go-devops-base:tools-jammy-0.4.4 /bin/bash
```

Then, within the docker image started in the last command:
```bash
cd /tmp && git clone https://github.com/geneontology/noctua_app_stack.git && cd noctua_app_stack
```

Test with:

```bash
go-deploy -h
```

If this command works, your environment should be okay.

## Add credentials for accessing and provisioning resources on AWS

### On host machine

Copy the ssh keys from your docker host into the running docker image, in `/tmp`:

```bash
docker cp go-ssh noctua-devops:/tmp
docker cp go-ssh.pub noctua-devops:/tmp
```

### In docker image

You should now have the following in your image:

```
/tmp/go-ssh
/tmp/go-ssh.pub
```

Check with:

```bash
ls -latr /tmp/go-ssh*
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

Replace the `REPLACE_ME`s for `aws_access_key_id` and `aws_secret_access_key` with your personal dev keys into the file.

Now export into your running docker environment:

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

### Update configuration file to instantiate instance on AWS

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
creates an Ansible inventory file.

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

### [WIP] Using non-master/non-noctua-models model source

WARNING: This is not currently working as expected. WIP.

Working through the example of wanting to use
`devops-noctua-models-experimental` (master) instead of the usual
`noctua-models`.

In vars.yaml, replace `noctua-models: master` with
`devops-noctua-models-experimental: master` entry.

In stage.yaml, add the following stanza after the "Clone repos that
are not staged" stanza. This will create a hard link, "simulating" the
usual name:

In template/startup.yaml, change `GITHUB_REPO` value to
"devops-noctua-models-experimental".

```ansible
  - name: Simulate noctua-models with hard link
    ansible.builtin.file:
      src: '{{ stage_dir }}/devops-noctua-models-experimental'
      dest: '{{ stage_dir }}/noctua-models'
      state: hard
```

The local blazegraph.jnl command would be:

```bash
rm -f /tmp/blazegraph.jnl && time java -Xmx8G -jar ./minerva-cli/bin/minerva-cli.jar --import-owl-models -j /tmp/blazegraph.jnl -f ~/local/src/git/devops-noctua-models-experimental/models/
```

WARNING: You may want to replace your image setup after you have
tainted it with the above non-standard instructions.

## Deployment

For production:

```bash
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose -dry-run --conf config-stack.yaml
go-deploy --workspace noctua-production-YYYY-MM-DD --working-directory aws -verbose --conf config-stack.yaml
```

For development:

```bash
go-deploy --workspace noctua-development-YYYY-MM-DD --working-directory aws -verbose -dry-run --conf config-stack.yaml
go-deploy --workspace noctua-development-YYYY-MM-DD --working-directory aws -verbose --conf config-stack.yaml
```

If the system prompts something like
```
The authenticity of host 'xxx.xxx.xxx.xxx (xxx.xxx.xxx.xx)' can't be established.
ED25519 key fingerprint is SHA256:------------------------.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```
Reply yes.

REMEMBER: it may take a while to fully spin up, even after it
returns. (5-10m?)

## Destroy Instance and Delete Workspace.

First, make sure you are deleting the correct workspace. For example:

```
go-deploy --workspace noctua-development-YYYY-MM-DD --working-directory aws -verbose -show
```

Now destroy. For example:

```
go-deploy --workspace noctua-development-YYYY-MM-DD --working-directory aws -verbose -destroy
```

## Readying for "full production"

### Production-ification with Cloudflare

To "finalize" a production setup, we'll want to take the instance that
we've created and place it behind the generic Cloudflare proxy.

Using "development" setup as example:

- Cloudflare
  - Go to geneontology.io
  - [DNS] -> [Records]
  - Edit the "noctua" record
	- Update the CNAME to your just-built noctua instance (e.g. noctua-development-YYYY-MM-DD.geneontology.io)
    - Make sure that "Proxy status" is set to _on_
	- Note: is may take a few minutes for the cert server at Cloudflare to catch up

### GitHub OAuth2

Noctua uses OAuth2 for authentication. See templates/github.yaml

- Go to: https://github.com/organizations/geneontology/settings/profile
- "Developer settings" -> "OAuth apps" -> "New OAuth app"
  - Application name: "Barista YYYY-MM-DD"
  - Homepage URL: `https://barista-development-YYYY-MM-DD.geneontology.io`
  - Application description: This Barista experimental implementation was setup on YYYY-MM-DD.
  - Authorization callback URL: `https://barista-development-YYYY-MM-DD.geneontology.io/auth/github/callback`
- [Create]
  - copy the Client ID
  - Click "Generate a new client secret" and copy Client secrets

Use these above for `github_client_id` and `github_client_secret`.

Note: GitHub OAuth2 is amenable to re-using the OAuth2 login between
instances. So, for example, if you have already made a
barista-development-2025-03-01.geneontology.io login created, you can
"update" it to a 2025-06-03 instance by just updating dates.

### [WIP] Model storage: AWS S3 version

From the noctua-devops docker image, first get AWS credentials over to
the hosting instance in AWS:

```bash
scp -i /tmp/go-ssh /tmp/go-aws-credentials ubuntu@noctua-development-2025-07-17.geneontology.io:/tmp
```

Then go over to new instance:

```bash
ssh -i /tmp/go-ssh ubuntu@noctua-development-2025-07-17.geneontology.io
```

On new instance, test our necessary commands with:

```bash
rm -f /home/ubuntu/go-cams.tgz || true
time tar --use-compress-program=pigz -cvf /home/ubuntu/go-cams.tgz -C /home/ubuntu/stage_dir/noctua-models/models .
AWS_SHARED_CREDENTIALS_FILE=/tmp/go-aws-credentials aws s3 cp /home/ubuntu/go-cams.tgz s3://go-cam-store-experimental
```

You should now be able to access and "push" models to S3.

To get this working in our versioning bucket, add the following to
crontab (`crontab -e`) as our current default `ubuntu` user:

```bash
0 0 * * * rm -f /home/ubuntu/go-cams.tgz || true
5 0 * * * tar --use-compress-program=pigz -cvf /home/ubuntu/go-cams.tgz -C /home/ubuntu/stage_dir/noctua-models/models .
10 0 * * * AWS_SHARED_CREDENTIALS_FILE=/tmp/go-aws-credentials aws s3 cp /home/ubuntu/go-cams.tgz s3://go-cam-store-experimental
```

This will push a tarball named "go-cams.tgz" of all models into
`go-cam-store-experimental` every 24 hours.

### [WIP] Model storage: GitHub version

TODO/WIP

Setup long timeout and token for local ubuntu user.

Then, add the following to the crontab (`crontab -e`) as our current
default `ubuntu` user:

```crontab
*/5 * * * * cd ~/staging_dir/noctua-models && git add * && git commit -a -m "automated commit"
*/30 * * * * cd ~/staging_dir/noctua-models && git push
```

TODO: Migrations would look like they do now, more or less?

### [WIP] Migrations SOP for AWS S3/GitHub hybrid

1. Stop minerva (docker image?)
2. Run the crontab commands to push files to S3
3. Locally, pull over the S3 files and unzip
4. cp these files to overlay onto github checkout
5. Commit github checkout
6. [Proceed with old SOP steps until files are finally committed to GH]
7. Stand up new instance of Noctua using this SOP
8. Move noctua.geneontology.io to this new instance
9. [Testing]
10. Destroy old instance

# Additional information

## Files

### Deploy a version of the Noctua editor (including minerva, barista, noctua):

- Important Ansible files:
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

### Preparing a Blazegraph journal locally

If you have minerva-cli.jar already built, and have the noctua-models that you want to use, you can just run the following command:

```bash
rm -f /tmp/blazegraph.jnl && time java -Xmx8G -jar ./minerva-cli/bin/minerva-cli.jar --import-owl-models -j /tmp/blazegraph.jnl -f ~/local/src/git/noctua-models/models/
```

You can then copy this into the docker image to continue the stack
setup:

```bash
docker cp /tmp/blazegraph.jnl noctua-devops:/tmp/blazegraph.jnl
```

Alternatively, for more detailed instructions, see
production/gen_journal.sh.sample for an example on for to generate
one.

## DNS

Note: DNS records are used for noctua and barista. The tool would create them during create phase and destroy them during destroy phase. See `dns_record_name` in the instance config file, ` noctua_host` and `barista_lookup_host` in the stack config file.

The aliases `noctua_host_alias` and `barista_lookup_host_alias` should be FQDN of an EXISTING DNS record. This reccord should NOT be managed by the tool otherwise the tool would delete them during the destroy phase.

Once the instance has been provisioned and tested, this DNS record would need to be updated manually to point to the public ip address of the vm.

## Debugging on instance

First, `ssh` to machine. username is `ubuntu`. Try using dns names,
rather than the direct IP address, to make sure they are correct.

Examination commands:

- `docker-compose -f stage_dir/docker-compose.yaml ps`
- `docker-compose -f stage_dir/docker-compose.yaml down` whenever you make any changes
- `docker-compose -f stage_dir/docker-compose.yaml up -d`
- `docker-compose -f stage_dir/docker-compose.yaml logs -f`
- Use `-dry-run` and copy and paste the command and execute it manually

## Appendix I: Development Environment

Start docker container `noctua-devops` in interactive mode.

```bash
docker run --rm --name noctua-devops -it geneontology/go-devops-base:tools-jammy-0.4.4 /bin/bash
```

In the command above we used the `--rm` option which means the
container will be deleted when you exit. If that is not the intent and
you want delete it later at your own convenience. Use the following
`docker run` command.

```bash
docker run --name noctua-devops -it geneontology/go-devops-base:tools-jammy-0.4.4 /bin/bash
```

Exit or stop the container: stop container with the intent of
restarting it. This equivalent to `exit` inside the container:

```bash
docker stop noctua-devops
```

Restart and attach (aka reattach/rejoin) to the container:

```bash
docker start -ia noctua-devops
cd /tmp/noctua_app_stack
```

Test with:

```bash
go-deploy --working-directory aws -list-workspaces -verbose
```

Remove a previously stopped container:

```bash
docker rm -f noctua-devops # get rid of it for good when ready.
```

## Appendix II: Updating software and integrating changes to the workbenches

The versions of minerva and noctua for the application stack are based on what is specified in docker-vars.yaml. If there are updates that can be released to production, then a build has to be created with the changes and pushed to the Docker Hub Container Image Library. The version number for minerva can be updated via minerva_tag and noctua version can be updated via noctua_tag.

Before operating with docker, you may need to login with
password/token:

```bash
docker login
```

If the operations seem odd: yes, we are grabbing these repos and building the
docker images in the root of `noctua_app_stack`.

### Build Noctua

Grab and build:

```bash
git checkout https://github.com/geneontology/noctua.git
docker build -f docker/Dockerfile.noctua -t 'geneontology/noctua:v6' -t 'geneontology/noctua:latest' noctua
```

Ensure the build works:

```bash
docker run --name mv6 -it geneontology/noctua:v6 /bin/bash
exit
```

Push to Dockerhub:

```bash
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


```bash
git checkout https://github.com/geneontology/minerva.git
docker build -f docker/Dockerfile.minerva -t 'geneontology/minerva:v7' -t 'geneontology/minerva:latest' minerva
```

Ensure the build works:

```bash
docker run --name mv7 -it geneontology/minerva:v7 /bin/bash
exit
```

Push to dockerhub:

```bash
docker push geneontology/minerva:v7
docker push geneontology/minerva:latest
```
