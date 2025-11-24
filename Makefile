.PHONY: format lint test

check: format lint

format:
	stylua .

lint:
	luacheck .
