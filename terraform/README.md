# Blockval terraform templates

## Setup

```
brew install terraform
echo "ENV := use1dev" > .env.make.local
make init
```

## Configuration

Terraform templates may be found within this directory and it's corresponding modules are stored in github in the [devops-automation](https://github.com/breather/devops-automation/tree/master/modules) repository. Any changes in infrastructure components would likely be done in either of these two locations.

Additionally, all configurable parameters ( that are not using defaults ) are located within the config/ folder and are loaded depending on the value of ENV.

## Configuration

Configuration may be provided in one of three ways ( in order of least precedence ) :
- `.env.make`: Makefile include file
- `.env.make.local`: Makefile include file
- `Makefile.local`: Makefile include file
- `environment`: Environment variables that have been defined
- `-e VAR=value`: Make command line arguments

Useful configuration parameters:
- `ENV`: The AWS environment to deploy to (use1dev or use1prod)
- `AWS_PROFILE`: The default AWS cli profile to use

## Usage

List potential commands
```
make help
```

Initiate terraform environment (once per environment)
```
make init -e ENV=use1prod
make init -e ENV=use1dev
```

Clear terraform cache in cache of issues
```
rm -fr .terraform .tmp
make init -e ENV=use1prod
make init -e ENV=use1dev
```

Generate a changeset
```
# Generate a changeset for dev
make plan
# -or- Generate a changeset for prod
make plan -e ENV=use1prod
```

Apply a changeset
```
# Apply a changeset for dev
make apply
# -or- Apply a changeset for prod
make apply -e ENV=use1prod
```

Destroy all resources
```
make destroy
```
