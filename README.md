# Docker image builder

A Makefile designed to build, tag and push docker images.

## Configuration

When executing, the Makefile will define certain environment variable defaults based on the environment it finds itself in. These may also be overriden by defining a configuration file located either in `./.env.make` or by the variable `CNF=./env.make`.

example:
```
# ./config/env.make
NAME=my-image
ORG=my-org

make -e CNF=./config/env.make
```

## Usage

Get basic help:
```
make help
```

Build a docker image which will be labeled $ORG/$NAME:$GIT_SHA1SUM
```
make build
```

Tag a docker image $ORG/$NAME:$GIT_SHA1SUM as $ORG/$NAME:$TAG
```
make tag -e TAG=TAG_VALUE
make tag-latest
```

Push a docker image to the docker repository
```
make push
make push-latest
```

Update Makefile from repository
```
make self-upgrade
```
