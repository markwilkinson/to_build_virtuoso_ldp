
# 2026 Update

## Process for building persistent Virtuoso LDP "ready to go out of the box"

Dockerfile_BUILD contains the dockerfile necessary to create a Virtuoso that has the VADs installed, and a basic ldp user.  _*SWITCH Dockerfile to this file now!*_

```
cp Dockerfile_BUILD Dockerfile
docker build -t markw/ldp_server_2026:1.0.0 .
```

the docker-compose file is fine to use at this point, and will initialize a virtuoso-db in the ./database folder.  _DO NOT CHANGE THE PASSWORD IN THE DOCKER COMPOSE FILE YET!!!_

`docker compose up -d`

login from http://localhost:8890/   (dba/dba)

Now create an LDP usere (e.g. ldp/ldp), and modify its permissions as you see fit (I tend to give it all SPARQL* permissions)

Enter the WebDAV Browser, and create a folder for LDP (I use /DAV/home/LDP/).  It should be set as LDP Enabled, and have read/write/execute for owner, and read for all.

`docker compose down`

If you want to make a distributable, not just a local image, make a copy of the virtuoso database using alpine:

`docker run --rm -v ./database:/from -v $(pwd)/preconfigured-db:/to alpine ash -c "cd /from && cp -av . /to"`

Switch to Dockerfile_DEPLOY and build (call the image whatever you wish...) for example

`docker build -t markw/ldp_server_2026:MacCompatible .`

docker-push that image. Anyone who pulls that image will have a pre-configured LDP server with a ldp/ldp user (read/write) and a /DAV/home/LDP folder ready to be used for HTTP POST/PUT operations.

Edit the password for the dba user now via the Conductor Users page!  You will probably be prompted to login again.
NOW Edit the docker-compose.yml to set the administrator password to whatever you set it above.
