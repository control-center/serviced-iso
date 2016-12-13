IMAGENAME  = base-iso-build
VERSION   ?= 1.0.1
LOCAL_TAG = zenoss/$(IMAGENAME):$(VERSION)
REMOTE_TAG = docker-registry-v2.zenoss.eng/$(IMAGENAME):$(VERSION)

.PHONY: build push clean

build:
	@echo Building image
	@docker build -f Dockerfile -t $(LOCAL_TAG) .

#
# Note: for the push to work, the docker daemon on this box must have the following
#       command line options: --insecure-registry docker-registry-v2.zenoss.eng
push:
	docker tag $(LOCAL_TAG) $(REMOTE_TAG)
	docker push $(REMOTE_TAG)

# Don't generate an error if the image does not exist
clean:
	-docker rmi $(LOCAL_TAG)

