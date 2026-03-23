# buildbot-master

Buildbot master for Zinnia and similar Jinx distributions.

## Initial setup

You will need to create a config. You can use the example config as a base,
but make sure to change the fields to your setup. The file must be called `user_config.py`.
The default file paths are designed to work with the docker-compose file.

```sh
cp user_config.py.example user_config.py
```

Next, add your secrets to the directory configured in your config variable `secrets_dir`.
Secrets are used for worker machines to authenticate themselves with the master.
The filename is the username, the contents are the password.
Note that the secret files must be only accessible by the user, i.e. mode 600.
Also make sure there are no trailing characters like newlines in the file.

```sh
echo 'my_password' > ./${secrets_dir}/my_worker
chmod 600 ./${secrets_dir}/my_worker
```

## Running Buildbot

### docker-compose

The docker-compose file creates a master and a webserver to host the results page. To start it, run it like any other container:

```sh
docker compose up -d
```

### Manual setup

```sh
# Install buildbot via pip (Create a venv if necessary).
pip install 'buildbot[bundle]'

# Create a master and start it.
buildbot create-master ${NAME}
buildbot start ${NAME}
```

## Creating a worker

Workers should not be run inside a container, but they can live on the same
machine as the master.

```sh
# Install buildbot-worker via pip (Create a venv if necessary).
pip install buildbot-worker

buildbot-worker create-worker ${BASE_DIR} ${MASTER_ADDRESS} ${NAME} ${PASSWORD}
buildbot-worker start ${BASE_DIR}
```
