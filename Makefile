.PHONY: check check-plugins install validate

check:
	./tests/check.zsh

check-plugins:
	./tests/plugins.zsh

validate:
	./scripts/install.zsh --no-activate

install:
	./scripts/install.zsh
