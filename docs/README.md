# Noctua App Stack

Install app stack using ansible on a single machine

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
## Deploying app stack: 

#### Clone this repo.

```sh
git clone https://github.com/abessiari/noctua_app_stack.git
cd noctua_app_stack
```

#### Modify `vars.yaml` as needed. Minimally you need to modify the following variables:
  - uri
  - username
  - password
  - dockerhub_user
    - needed to push images to dockerhub and to stage on a remote machine
  - host
    - On mac if using wireless, you can use `ipconfig getifaddr en0`

#### Build images.

```sh
ansible-playbook build_images.yaml
docker image list | egrep 'minerva|noctua|golr'
```

#### Push images.

```sh
ansible-playbook push_images.yaml
```

#### Stage artifacts.
  - Create and stage blazegraph journal.
  - Stage repos
    - noctua-form, noctua-landing-page, noctua-models, go-site
  - Note: Stage the journals below to speed up minerva start up time.
    - Create stage_dir if it does not exist
    - Copy`blazegraph.jnl` to stage_dir
    - Copy`blazegraph-go-lego-reacto-neo.jnl` to stage_dir

```sh
ansible-playbook stage.yaml
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
