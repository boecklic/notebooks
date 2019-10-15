DOCKER = docker
RSYNC = rsync
DOCKERHUB_USER = boecklic
PWD := $(shell pwd)
LOCAL_UID := $(shell id -u $$USER)
CMD ?=
SRCDIR = .
CONVERTED_HTML := converted/html
CONVERTED_SVG := converted/svg
CONVERTED_PNG := converted/png
SRCEXT := ipynb
HTMLEXT := html
DIOEXT := dio
SVGEXT := svg
PNGEXT := png

# find all 'true' .ipynb files, exclude checkpoint files
IPYNB_FILES := $(shell find $(SRCDIR) -type f -name '*.$(SRCEXT)' | grep -v  ".ipynb_checkpoints")
HTML_FILES := $(patsubst $(SRCDIR)/%,$(CONVERTED_HTML)/%,$(IPYNB_FILES:.$(SRCEXT)=.$(HTMLEXT)))
DIO_FILES := $(shell find $(SRCDIR) -type f -name '*.$(DIOEXT)' | grep -v ".ipynb_checkpoints")
SVG_FILES := $(patsubst $(SRCDIR)/%,$(CONVERTED_SVG)/%,$(DIO_FILES:.$(DIOEXT)=.$(SVGEXT)))
PNG_FILES := $(join \
	$(dir $(DIO_FILES:.$(DIOEXT)=.$(PNGEXT))), \
	$(addprefix \
		assets/, \
		$(notdir $(DIO_FILES:.$(DIOEXT)=.$(PNGEXT))) \
	) \
)
#PNG_FILES := $(DIO_FILES:.$(DIOEXT)=.$(PNGEXT))
CONV_PNG_FILES := $(patsubst $(SRCDIR)/%,$(CONVERTED_PNG)/%,$(DIO_FILES:.$(DIOEXT)=.$(PNGEXT)))

#DOCKER_TAG=0.35.6
DOCKER_TAG=1.1.4

.PHONY: all
all: vars $(HTML_FILES)
	@echo "Done"

.PHONY: vars
vars:
	@echo "IPYNB_FILES: $(IPYNB_FILES)"
	@echo "HTML_FILES: $(HTML_FILES)"
	@echo "DIO_FILES: $(DIO_FILES)"
	@echo "SVG_FILES: $(SVG_FILES)"
	@echo "PNG_FILES: $(PNG_FILES)"
	#@echo "PNG_FILES: $(TMP_FILES)"
	#@echo $(subst assets/,,$(PNG_FILES))

.PHONY: update
update:
	# update the docker image
	docker pull $(DOCKERHUB_USER)/jupylab\:$(DOCKER_TAG)

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
		-v $(PWD):/home/user $(DOCKERHUB_USER)/jupylab\:$(DOCKER_TAG) $(CMD)

# for details about how to exclude cells when converting
# https://stackoverflow.com/a/48084050
# requires this extension
# https://github.com/jupyterlab/jupyterlab-celltags
$(CONVERTED_HTML)/%.$(HTMLEXT): $(SRCDIR)/%.$(SRCEXT)
	@echo $<
	@echo $@
	@echo $(patsubst $PWD/%,%,$<)
	$(DOCKER) run --rm --init \
		-e LOCAL_UID=$(LOCAL_UID) \
		-v $(PWD):/home/user $(DOCKERHUB_USER)/jupylab\:$(DOCKER_TAG) jupyter nbconvert \
			--execute \
			--TagRemovePreprocessor.remove_input_tags='{"hidden"}' \
			--TagRemovePreprocessor.remove_cell_tags='{"hidden_cell"}' \
			--to html $< \
			--output-dir $(dir $@)

$(CONVERTED_SVG)/%.$(SVGEXT): $(SRCDIR)/%.$(DIOEXT)
	@echo $<
	@echo $@
	@echo $(patsubst $PWD/%,%,$<)
	mkdir -p $(dir $@)
	$(DOCKER) run --rm --init \
		-e LOCAL_UID=$(LOCAL_UID) \
		-v $(PWD):/home/user $(DOCKERHUB_USER)/jupylab\:$(DOCKER_TAG) drawio-batch $< $@

#%.$(PNGEXT): %.$(DIOEXT)
#	@echo $<
#	@echo $@
#	@echo $(patsubst $PWD/%,%,$<)
#	mkdir -p $(dir $@)
#	$(DOCKER) run --rm --init \
#		-e LOCAL_UID=$(LOCAL_UID) \
#		-v $(PWD):/home/user $(DOCKERHUB_USER)/jupylab\:$(DOCKER_TAG) drawio-batch $< $@

#$(CONV_PNG_FILES)/%.$(PNGEXT): $(SRCDIR)/%.$(DIOEXT)
#	@echo "tst"
#	@echo $<
#	@echo $@
#	@echo $*

#.SECONDEXPANSION:
#%.png.dio: %.dio
#	@echo $<
#	@echo $@
#	@echo $*

.SECONDEXPANSION:
#%.png.dio: %.dio
%.$(PNGEXT): 
	#$$(subst assets/,,$$(addsuffix .dio,$$@))
	@echo "blah"
	@echo $<
	@echo $@
	@echo $*
	$(DOCKER) run --rm --init \
		-e LOCAL_UID=$(LOCAL_UID) \
		-v $(PWD):/home/user $(DOCKERHUB_USER)/jupylab\:$(DOCKER_TAG) drawio-batch $(subst assets/,,$(subst .png,.dio,$@)) $@


#%.$(PNGEXT): $$(addsuffix .dio,$$(subst assets/,,$$@))

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

.PHONY: export_svg
export_svg: $(SVG_FILES)
	# - Generate svg files from all .dio files found in
	#   in this folder and subfolders
	# - rsync all svg files to public_html
	# - rsync all assets to public_html
	@echo "sync files..."
	$(RSYNC) -av --relative converted/svg/./** /home/ltboc/src/public_html/notebooks/html/
	#@echo "sync assets..."
	#$(RSYNC) -av --relative ././assets/** ././**/assets/** /home/ltboc/src/public_html/notebooks/html/

.PHONY: export_png
export_png: $(PNG_FILES)
	# - Generate svg files from all .dio files found in
	#   in this folder and subfolders
	# - rsync all svg files to public_html
	# - rsync all assets to public_html
	@echo "nothing to sync..."
	#$(RSYNC) -av --relative converted/svg/./** /home/ltboc/src/public_html/notebooks/html/

