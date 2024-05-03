###################
# PARAMETERS TO MODIFY
IMAGE_NAME = default
IMAGE_TAG = 1.0
###################
# FIXED PARAMETERS
DOCKER_RUN = docker run -it --entrypoint=bash -w /home -v $(PWD):/home/
DOCKER_IMAGE = $(IMAGE_NAME):$(IMAGE_TAG)
DOCKERFILE_PIPTOOLS = Dockerfile_piptools
DOCKER_IMAGE_PIPTOOLS = piptools:latest
###################

#
# build image
#
.PHONY : build
build: .build

.build: Dockerfile requirements.txt
	$(info ***** Building Image *****)
	docker build -t $(DOCKER_IMAGE) .
	@touch .build

requirements.txt: .build_piptools requirements.in
	$(info ***** Pinning requirements.txt *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE_PIPTOOLS) -c "pip-compile --output-file requirements.txt requirements.in"
	@touch requirements.txt

.build_piptools: Dockerfile_piptools
	$(info ***** Building Image piptools:1.0 *****)
	docker build -f $(DOCKERFILE_PIPTOOLS) -t $(DOCKER_IMAGE_PIPTOOLS) .
	@touch .build_piptools

build-piptools: .build_piptools 

.PHONY : upgrade
upgrade:
	$(info ***** Upgrading dependencies *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE_PIPTOOLS) -c "pip-compile --upgrade --output-file requirements.txt requirements.in"
	@touch requirements.txt

#
# Run commands
#
.PHONY : shell
shell: build
	$(info ***** Creating shell *****)
	$(DOCKER_RUN) -p 8265:8265 -p 5000:5000 $(DOCKER_IMAGE)
# Note: to start Ray server, start it as: ‘ray.init(dashboard_port=8265, dashboard_host="0.0.0.0")‘
# Then open that Ray server in your browser with “localhost:8265‘

.PHONY : notebook
notebook: build
	$(info ***** Starting a notebook *****)
	$(DOCKER_RUN) -p 8888:8888 $(DOCKER_IMAGE) -c "jupyter notebook --ip=$(hostname -I) --no-browser --allow-root"

.PHONY : notebook
mlflow_server: build
	$(info ***** Starting the mlflow server *****)
	$(DOCKER_RUN) -p 5000:5000 $(DOCKER_IMAGE) -c "mlflow server -h 0.0.0.0"

#
# Cleaning
#
.PHONY : clean
clean:
	$(info ***** Cleaning files *****)
	rm -rf .build .build_piptools requirements.txt
