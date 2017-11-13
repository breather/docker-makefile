# Blockval management terraform templates

## Setup

```
brew install terraform
echo "AWS_ENV := use1dev" > .env.make.local
make init
```

## Configuration

Configuration may be provided in one of three ways ( in order of least precedence ) :
- `.env.make`: Makefile include file
- `.env.make.local`: Makefile include file
- `Makefile.local`: Makefile include file
- `environment`: Environment variables that have been defined
- `-e VAR=value`: Make command line arguments

Useful configuration parameters:
- `AWS_ENV`: The AWS environment to deploy to (use1dev or use1prod)
- `AWS_PROFILE`: The default AWS cli profile to use
- `ASSUME_ROLE`: The AWS role to assume before executing terraform
- `ASSUME_ROLE_PROFILE`: The AWS profile which contains a role to detect

The `ASSUME_ROLE_PROFILE` variable will attempt to autodetect what it should be set as when left undefined. Possible values, in order of precedence, are: `AWS_ENV` and `AWS_PROFILE`.

## Usage

List potential commands
```
make help
```

Generate a changeset
```
make plan
```

Apply a changeset
```
make apply
```

Destroy everything
```
make destroy
```
