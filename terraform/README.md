# Blockval management terraform templates

## Setup

```
brew install terraform
echo "AWS_ENV      := use1dev" > .env.make.local
echo "AWS_ROLE_ARN := THE_ROLE_TO_USE" > .env.make.local
make init
```

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
