
# 2026 Update

## Process for building persistent Virtuoso LDP "ready to go out of the box"

Dockerfile_BUILD contains the dockerfile necessary to create a Virtuoso that has the VADs installed, and a basic ldp user.  _*SWITCH Dockerfile to this file now!*_

```
cp Dockerfile_BUILD Dockerfile
docker build -t markw/ldp_server_2026:1.0.0 .
```

the docker-compose file is fine to use at this point, and will initialize a virtuoso-db in the ./database folder

`docker compose up -d`

login from http://localhost:8890/   (dba/dba)

Check that the ldp user is created (ldp/ldp), and modify its permissions as you see fit (I tend to give it all SPARQL* permissions)

Enter the WebDAV Browser, and create a folder for LDP (I use /DAV/home/LDP/).  It should be set as LDP Enabled, and have read/write/execute for owner, and read for all.

`docker compose down`

now make a copy of the virtuoso database using alpine:

`docker run --rm -v ./database:/from -v $(pwd)/preconfigured-db:/to alpine ash -c "cd /from && cp -av . /to"`

now switch to Dockerfile_DEPLOY and build (call the image whatever you wish...)

`docker build -t markw/ldp_server_2026:MacCompatible .`

docker-push that image. Anyone who pulls that image will have a pre-configured LDP server with a ldp/ldp user (read/write) and a /DAV/home/LDP folder ready to be used for HTTP POST/PUT operations.

