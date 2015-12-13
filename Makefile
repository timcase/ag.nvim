TARGS := $(shell sed -n 's/^\([-a-z]\+\):.*/\1/p' Makefile|sort -u|xargs)
.PHONY: $(TARGS)
.SILENT:

all: test

test:
	./scripts/suite.sh

debug:
	./scripts/suite.sh --verbose

auto:
	$(MAKE) test || $(MAKE) debug

clean:
	rm -rf $(dir $(shell mktemp --dry-run --tmpdir))/vader.vim
