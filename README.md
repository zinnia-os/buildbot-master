# buildbot-master

Buildbot master for Zinnia and similar Jinx distributions.

Requires **Jinx 0.10** or newer in the distribution repository. Older Jinx
releases used a separate `host-build` command and did not produce host
packages as XBPS packages, neither of which this configuration supports any
more.

## Package repositories

Each builder publishes two directories, both served by the results web server:

- `results` -> target packages, built for the architecture named in `archs`.
- `host_results` -> host packages, built for the worker machine's own
  architecture. These need a directory of their own because their repository
  index is named after the build machine's architecture, which on a native
  build would collide with the target index.

Point the distribution's `Jinxfile` at them so builders can pull prebuilt
packages instead of rebuilding everything:

```sh
JINX_REPO_URL=https://example.org/${JINX_ARCH}
JINX_HOST_REPO_URL=https://example.org/${JINX_ARCH}/host
```

Both downloads are best effort. A builder whose repositories are empty (or not
published yet) just builds more, and populates them on the way.

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
echo -n 'my_password' > ./${secrets_dir}/my_worker
chmod 600 ./${secrets_dir}/my_worker
```

Generate the RSA repository-signing key once. Keep this key backed up and do
not copy it to build workers.
Changing or losing it changes the identity of the package repository.

```sh
openssl genrsa -out ./${secrets_dir}/repository-signing-key.pem 4096
chmod 600 ./${secrets_dir}/repository-signing-key.pem
```

Set `signing_key` and `signed_by` in `user_config.py`. The first successful
build indexes all packages already present in each results directory, embeds
the public key in repodata, and creates any missing `.xbps.sig2` files.

To publish packages that already exist without waiting for another build, run
the publisher once for each repository after building the master image:

```sh
docker compose run --rm --no-deps buildbot \
    /usr/local/bin/publish-xbps-repository \
    /buildbot/results/x86_64 \
    /buildbot/secrets/repository-signing-key.pem \
    "Zinnia Bootstrap" x86_64

docker compose run --rm --no-deps buildbot \
    /usr/local/bin/publish-xbps-repository \
    /buildbot/results/x86_64/host \
    /buildbot/secrets/repository-signing-key.pem \
    "Zinnia Bootstrap" x86_64
```

## Running Buildbot

### docker-compose

The docker-compose file creates a master and a webserver to host the results page. To start it, run it like any other container:

```sh
docker compose build buildbot
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
machine as the master. Beyond buildbot-worker itself, Jinx needs the following
on the worker: `bash`, `awk`, `git`, GNU `make`, `grep`, `sed`, `tar`, `gzip`,
`zstd`, `wget`, `sha256sum` (coreutils), `find` and `xargs` (findutils), `free`
(procps) and `unshare` (util-linux). Unprivileged user namespaces must be
enabled, as Jinx builds inside a container it sets up itself.

```sh
# Install buildbot-worker via pip (Create a venv if necessary).
pip install buildbot-worker

buildbot-worker create-worker ${BASE_DIR} ${MASTER_ADDRESS} ${NAME} ${PASSWORD}
buildbot-worker start ${BASE_DIR}
```
