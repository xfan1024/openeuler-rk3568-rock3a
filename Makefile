VARIANT ?= rock3a-base
REGISTRY ?= xfan1024/openeuler:22.03-$(VARIANT)
DOCKERFILE ?= Dockerfile.$(VARIANT)
GENIMAGE ?= xfan1024/genimage:v16
IMAGENAME := openEuler.img

.PHONY: all clean scp build-rootfs-docker-image

all: output/$(VARIANT)/$(IMAGENAME).gz

clean:
	rm -rvf output/$(VARIANT)/

build-rootfs-docker-image:
	cd rootfs; docker build . -f $(DOCKERFILE) -t $(REGISTRY)

output/$(VARIANT)/rootfs.tar: build-rootfs-docker-image
	mkdir -p output/$(VARIANT)
	cid=$$(docker create $(REGISTRY)) && \
	    docker export $$cid -o output/$(VARIANT)/rootfs.tar && \
	    docker rm $$cid

output/$(VARIANT)/$(IMAGENAME): output/$(VARIANT)/rootfs.tar
	docker run --rm -it \
	    -v$(CURDIR)/genimage:/work/genimage:ro \
	    -v$(CURDIR)/output/$(VARIANT)/rootfs.tar:/work/rootfs.tar:ro \
	    -v$(CURDIR)/output/$(VARIANT):/work/output:rw \
		-eHOSTUID=$$(id -u) -eHOSTGID=$$(id -g) \
	    -w /work $(GENIMAGE) \
	    genimage/buildimage.sh

output/$(VARIANT)/$(IMAGENAME).gz: output/$(VARIANT)/$(IMAGENAME)
	gzip -fk output/$(VARIANT)/$(IMAGENAME)
