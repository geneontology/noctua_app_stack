# Noctua App Stack

- Deploy app stack using ansible playbooks on a single machine:
  - build_images.yaml
    - builds all docker images on local machine.
  - push_images.yaml
    - pushes images to dockerhub if planning on staging to a remote machine.
  - stage.yaml
    - Tasks are executed on staging machine which can be local or remote.
   

## Requirements 

- The steps below were successfully tested using:
    - MacOs (10.15.3)
    - Docker (19.03.5)
    - Docker Compose (1.25.2)
    - Ansible (2.10.3), Python (3.8.5), docker (4.3.1)
    
- Notes:
    - Docker was given 3 CPUs and 8G RAM. (on mac see Docker Preferences | Resources)
    - python 2.7 should work as well.

## Installing ansible and ansible docker plugin 

The ansible docker plugin is used to buid docker images.

```sh
pip install ansible
pip install docker 
```

## Clone this repo.

```sh
git clone https://github.com/abessiari/noctua_app_stack.git
cd noctua_app_stack
```

## Building Docker Images:

#### Build images.
- Make sure you set docker_hub_user in vars.yaml to your dockerhub user account if planning on staging to a remote machine.

```sh
ansible-playbook build_images.yaml
docker image list | egrep 'minerva|noctua|golr'
```

#### Push images.
- Make sure you set docker_hub_user in vars.yaml to your dockerhub user account if planning on staging to a remote machine.

```sh
ansible-playbook push_images.yaml
```
## Staging app stack: 

#### Modify `vars.yaml`. 
- These can also be set on command line using the -e flag.
  - Barista:
    - uri
    - username
    - password
    
#### Stage Artifacts.
- Staging tasks at a glance:
  - Creates blazegraph journal.
  - Creates Solr Index
  - Clones repos
    - noctua-form, noctua-landing-page, noctua-models, go-site
  - Creates docker-compose and configuration files from templates.
- Staging to a remote machine:
  - Refer to [this document](./docs/AWS_README.md) on provisionning an AWS.

```sh
# on Mac:
export HOST=`ipconfig getifaddr en0`
ansible-playbook -e "host=$HOST" -i "localhost," stage.yaml
```
#### Bring up stack using docker-compose.
Two docker-compose files are staged:
  - docker-compose-golr.yaml
    - Uses a lightweight solr image for golr
  - docker-compose-amigo.yaml
    - Uses the official geneontology/amigo-standalone for golr

```sh
# assuming stage_dir is in current directory and docker-compose-golr.yaml is used:
docker-compose -f stage_dir/docker-compose-golr.yaml up -d

# minerva takes a long time to start up the first time
# Tail minerva logs to see its progress
docker-compose -f stage_dir/docker-compose-golr.yaml logs -f minerva
# Or tail all logs
docker-compose -f stage_dir/docker-compose-golr.yaml logs -f

# When minerva is ready all other services should be up
docker-compose -f stage_dir/docker-compose-golr.yaml ps
```

#### Access noctua from a browser using `http://localhost:{{ noctua_proxy_port }}`
- Use `http://localhost:8080` if default `noctua_proxy_port` was used

#### Bring down stack using docker-compose. 

```sh
docker-compose -f stage_dir/docker-compose-golr.yaml down
# kill works faster ...
docker-compose -f stage_dir/docker-compose-golr.yaml kill
#delete containers:
docker-compose -f stage_dir/docker-compose-golr.yaml rm -f
```
