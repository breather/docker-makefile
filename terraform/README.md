# Blockval management terraform templates

## Setup

```
brew install terraform
echo "AWS_ENV := use1dev" > .env.make.local
make init
```

## Usage

```
make help
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
