DOCKER = docker
RSYNC = rsync
DOCKERHUB_USER = boecklic
PWD := $(shell pwd)
LOCAL_UID := $(shell id -u $$USER)
CMD ?= 

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

.PHONY: export
export:
	#@echo ${LOCAL_UID}
	# - Bind container port 8888 (the notebooks port)
	#   to host port 80
	# - set the env variable LOCAL_UID to the host users
	#   uid running the container
	# - mount the local directory as /home/user inside
	#   the container
	$(DOCKER) run --rm -it --init \
		-e LOCAL_UID=$(LOCAL_UID) \
		-v $(PWD):/home/user $(DOCKERHUB_USER)/jupylab\:latest jupyter nbconvert --execute --to html mvt/roadmap_openlayers.ipynb --output-dir converted/html
	$(RSYNC) converted/html/* /home/ltboc/src/public_html/notebooks/
