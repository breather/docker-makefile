SHELL           := bash
.SHELLFLAGS     := -eu -o pipefail -c
.DEFAULT_GOAL   := help


MAKE_VERSION    := master
MAKE_INCLUDE    ?= $(TMPDIR)Makefile.docker.$(MAKE_VERSION)
MAKE_SOURCE      = https://raw.githubusercontent.com/breather
MAKE_SOURCE     := $(MAKE_SOURCE)/makefiles/$(MAKE_VERSION)/docker/include


ifeq (,$(wildcard $(MAKE_INCLUDE)))
$(shell touch $(MAKE_INCLUDE))
$(shell make makefile.upgrade)
endif


.PHONY: makefile.upgrade
makefile.upgrade:
	rm $(MAKE_INCLUDE)
	wget --unlink -q -O $(MAKE_INCLUDE) $(MAKE_SOURCE)


export
-include $(MAKE_INCLUDE)

#  vim: set ft=make ts=2 sw=2 noet :

