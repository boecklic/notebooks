DOCKER = docker
DOCKERHUB_USER = boecklic
PWD := $(shell pwd)
LOCAL_UID := $(shell id -u $$USER)
CMD ?= 


.PHONY: run
run:
	#@echo ${LOCAL_UID}
	# - Bind container port 8888 (the notebooks port)
	#   to host port 80
	# - set the env variable LOCAL_UID to the host users
	#   uid running the container
	# - mount the local directory as /home/user inside
	#   the container
	$(DOCKER) run -it --init -p 8888:8888 \
		-e LOCAL_UID=$(LOCAL_UID) \
		-v $(PWD):/home/user $(DOCKERHUB_USER)/jupylab\:latest $(CMD)
