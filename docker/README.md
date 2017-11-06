# Docker image builder

A Makefile designed to build, tag and push docker images.

## Configuration

When executing, the Makefile will define certain environment variable defaults based on the environment it finds itself in. These may also be overriden by defining a configuration file.

Configuration files may be found in:
- ${CNF:-.env.make}
- ${CNF:-.env.make}.local
- ${WORKING_DIR:-.}/Makefile.local

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
```

Push a docker image to the docker repository
```
make push
```

Update Makefile from repository
```
make self-upgrade
```
