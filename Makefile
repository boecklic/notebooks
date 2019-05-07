DOCKER = docker
RSYNC = rsync
DOCKERHUB_USER = boecklic
PWD := $(shell pwd)
LOCAL_UID := $(shell id -u $$USER)
CMD ?=
SRCDIR = .
CONVERTED_HTML := converted/html
SRCEXT := ipynb
HTMLEXT := html

# find all 'true' .ipynb files, exclude checkpoint files
IPYNB_FILES := $(shell find $(SRCDIR) -type f -name '*.$(SRCEXT)' | grep -v  ".ipynb_checkpoints")
HTML_FILES := $(patsubst $(SRCDIR)/%,$(CONVERTED_HTML)/%,$(IPYNB_FILES:.$(SRCEXT)=.$(HTMLEXT)))

.PHONY: all
all: vars $(HTML_FILES)
	@echo "Done"

.PHONY: vars
vars:
	@echo "IPYNB_FILES: $(IPYNB_FILES)"
	@echo "HTML_FILES: $(HTML_FILES)"


.PHONY: update
update:
	# update the docker image
	docker pull $(DOCKERHUB_USER)/jupylab\:latest

.PHONY: run
run:
	#@echo ${LOCAL_UID}
	# - Bind container port 8888 (the notebooks port)
	#   to host port 80
	# - set the env variable LOCAL_UID to the host users
	#   uid running the container
	# - mount the local directory as /home/user inside
	#   the container
	$(DOCKER) run --rm -it --init -p 8888:8888 \
		-e LOCAL_UID=$(LOCAL_UID) \
		-v $(PWD):/home/user $(DOCKERHUB_USER)/jupylab\:latest $(CMD)

$(CONVERTED_HTML)/%.$(HTMLEXT): $(SRCDIR)/%.$(SRCEXT)
	@echo $<
	@echo $@
	@echo $(patsubst $PWD/%,%,$<)
	$(DOCKER) run --rm --init \
		-e LOCAL_UID=$(LOCAL_UID) \
		-v $(PWD):/home/user $(DOCKERHUB_USER)/jupylab\:latest jupyter nbconvert --execute --to html $< --output-dir $(dir $@)

.PHONY: export
export: $(HTML_FILES)
	# - Generate html files from all .ipynb files found in
	#   in this folder and subfolders
	# - rsync all html files to public_html
	# - rsync all assets to public_html
	@echo "sync files..."
	$(RSYNC) -av --relative converted/./html/** /home/ltboc/src/public_html/notebooks/
	@echo "sync assets..."
	$(RSYNC) -av --relative ././assets/** ././**/assets/** /home/ltboc/src/public_html/notebooks/html/
