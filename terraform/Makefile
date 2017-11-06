# Makefile config
#
.DEFAULT = help
.PHONY: $(MAKEFILE_LIST)
SHELL := '/bin/bash'
SCRIPT_BASE   := https://raw.githubusercontent.com/breather/makefiles
SCRIPT_SOURCE := $(SCRIPT_BASE)/master/terraform/Makefile

# Command variables
#
AWS                    = aws
AWS_CMD                = $(AWS) $(AWS_FLAGS)
AWS_FLAGS              = #--profile $(AWS_PROFILE)
AWS_PROFILE           ?= default
TERRAFORM              = terraform
TERRAFORM_CMD          = $(TERRAFORM) $(TERRAFORM_FLAGS)
TERRAFORM_FLAGS        =
WGET                   = wget
WGET_CMD               = $(WGET) $(WGET_FLAGS)
WGET_FLAGS             =

# Optionally include config file
#
CNF                   ?= .env.make
-include ${CNF}
-include ${CNF}.local
-include $(shell pwd)/Makefile.local

# Overwritable variables
#
NAME                  ?= terraform
WORKING_DIR           ?= $(PWD)

# Targets
#
help: ## Show this help message.
	$(info Terraform helper)
	$(info )
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

assume: assume.verify ## Assume an aws role and export session credentials
ifndef AWS_ROLE_ARN
else
  ifndef AWS_SESSION_TOKEN
  CREDENTIALS := $(shell aws sts assume-role \
    --role-arn ${AWS_ROLE_ARN} \
    --role-session-name=${NAME} \
    --query Credentials \
    --output text)
  export AWS_ACCESS_KEY_ID     := $(word 1, $(CREDENTIALS))
  export AWS_SECRET_ACCESS_KEY := $(word 3, $(CREDENTIALS))
  export AWS_SESSION_TOKEN     := $(word 4, $(CREDENTIALS))
  endif
endif

assume.exec: assume ## Assume an aws role and execute COMMAND="cmd args"
	$(COMMAND)

assume.verify:
ifndef AWS_ENV
  $(error AWS_ENV is not defined, should be use1dev or use1prod)
endif
ifdef AWS_PROFILE
  $(warning AWS_PROFILE variable is defined, this may be bad)
endif

activate: ## Activate terraform workspace
ifndef ENV
	$(error "ENV was not set")
endif
	$(TERRAFORM_CMD) workspace select $(ENV)

apply: ## Apply terraform template
	@echo "Applying changes to Infrastracture"
	@make assume.exec COMMAND="$(TERRAFORM_CMD) apply -parallelism=80 .tmp/plan_stg"
	@make clean

confirm:
	@read -r -t 5 -p "Do you wish to continue (timeout 5s) [y/n]: " CONTINUE; \
	if [ ! $$CONTINUE == "y" ] || [ -z $$CONTINUE ]; then \
		echo "Aborting" ; \
		exit 1; \
	fi

clean: ## Delete temporary files
	rm -f .tmp/plan_stg #$(TERRAFORM_CMD).tfstate*

destroy: ## Delete terraform stack
	@echo "Destroying terraform stack"
	@make confirm
	@make assume.exec COMMAND="$(TERRAFORM_CMD) destroy -force" \

format: ## Format terraform files
	@echo "Formating terraform code"
	$(TERRAFORM_CMD) fmt

get: ## Update terraform modules
	@echo "Updating terraform modules"
	$(TERRAFORM_CMD) get -update

init: assume ## Initialize terraform state
	@echo
	@echo "Ensuring required CLI tools exist"
	aws --version
	$(TERRAFORM_CMD) -version
	@echo "Initializing terraform state"
	$(TERRAFORM_CMD) init \
  -backend-config="acl=private" \
  -backend-config="bucket=breather-$(AWS_ENV)-terraform" \
  -backend-config="key=$(AWS_ENV)/$(BACKEND_KEY)" \
  -backend-config="dynamodb_table=$(AWS_ENV)-terraform" \
  -backend-config="region=us-east-1" \
  -force-copy \
  -input=false
	@echo
	@echo "Your environment: $$($(TERRAFORM_CMD) workspace list | grep '^\*' | awk '{print $$2}')"

plan: assume format get ## Verify infrastructure changes
	@echo "Checking Infrastracture"
	@mkdir -p .tmp || true
	$(TERRAFORM_CMD) plan \
  -parallelism=80 \
  -refresh=true \
  -module-depth=-1 \
  -out .tmp/plan_stg

setup: init get

show: ## Show infrastructure change plan
	@echo "Showing plan to apply"
	$(TERRAFORM_CMD) show .tmp/plan_stg

output: ## Show infrastructure outputs
	@$(TERRAFORM_CMD) output

self.upgrade: ## Upgrade this instance of the Makefile
	$(WGET_CMD) --unlink -q $(SCRIPT_SOURCE) -O Makefile

#  vim: set ft=make ts=2 sw=2 noet :
