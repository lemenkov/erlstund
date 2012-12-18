REBAR ?= $(shell which rebar 2>/dev/null || which ./rebar)
REBAR_FLAGS ?=

VSN := "0.0.1"
BUILD_DATE := `LANG=C date +"%a %b %d %Y"`
NAME := stund

ERLANG_ROOT := $(shell erl -eval 'io:format("~s", [code:root_dir()])' -s init stop -noshell)
ERLDIR=$(ERLANG_ROOT)/lib/$(NAME)-$(VSN)

EBIN_DIR := ebin
ERL_SOURCES  := $(wildcard src/*.erl)
ERL_OBJECTS  := $(ERL_SOURCES:src/%.erl=$(EBIN_DIR)/%.beam)
APP_FILE := $(EBIN_DIR)/$(NAME).app

all: compile

compile:
	@VSN=$(VSN) BUILD_DATE=$(BUILD_DATE) $(REBAR) compile $(REBAR_FLAGS)

rel: compile
	rm -rf rel/stund
	$(REBAR) generate $(REBAR_FLAGS)

check: test
test: all
	$(REBAR) eunit $(REBAR_FLAGS)

install: all
	@test -d $(DESTDIR)$(ERLDIR)/ebin || mkdir -p $(DESTDIR)$(ERLDIR)/ebin

	@install -p -m 0644 $(APP_FILE) $(DESTDIR)$(ERLDIR)/ebin
	@install -p -m 0644 $(ERL_OBJECTS) $(DESTDIR)$(ERLDIR)/ebin

clean:
	@$(REBAR) clean $(REBAR_FLAGS)

uninstall:
	@if test -d $(ERLDIR); then rm -rf $(ERLDIR); fi
	@echo "$(NAME) uninstalled. \n
