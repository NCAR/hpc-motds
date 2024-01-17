latests := $(wildcard */latest)

all:
	@echo $(latests)


.sync_stamp: $(latests) Makefile
	@[ -z "$${status_string}" ] || echo $${status_string}
	@rm -f $@
	@which git
	git add $(latests)
	git status $(latests) 2>&1 | grep "nothing to commit, working tree clean" >/dev/null 2>&1 || { git commit -m "Adding MOTD entries from $$(pwd) on $$(date)"; git push; }
	@date > $@
	@echo "Done at $$(cat $@)"
