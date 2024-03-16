PROJECT_DIR    := $(shell pwd)
DL_DIR         ?= $(PROJECT_DIR)/dl
OUTPUT_DIR     ?= $(PROJECT_DIR)/output
CCACHE_DIR     ?= $(PROJECT_DIR)/buildroot-ccache
LOCAL_MK       ?= $(PROJECT_DIR)/mistex.mk
EXTRA_PKGS     ?=
DOCKER_OPTS    ?=
DOCKER         ?= docker

-include $(LOCAL_MK)

DOCKER_REPO := mistex
IMAGE_NAME  := mistex-buildroot

TARGETS := $(sort $(shell find $(PROJECT_DIR)/configs/ -not -name '*common*' | sed -n 's/.*\/mistex-\(.*\)_defconfig/\1/p'))
UID  := $(shell id -u)
GID  := $(shell id -g)

$(if $(shell which $(DOCKER) 2>/dev/null),, $(error "$(DOCKER) not found!"))

UC = $(shell echo '$1' | tr '[:lower:]' '[:upper:]')

default: vars

vars:
	@echo "Supported targets:  $(TARGETS)"
	@echo "Project directory:  $(PROJECT_DIR)"
	@echo "Download directory: $(DL_DIR)"
	@echo "Build directory:    $(OUTPUT_DIR)"
	@echo "ccache directory:   $(CCACHE_DIR)"
	@echo "Extra options:      $(EXTRA_OPTS)"
	@echo "Docker options:     $(DOCKER_OPTS)"
	@echo "Make options:       $(MAKE_OPTS)"

build-docker-image:
	$(DOCKER) build . -t $(DOCKER_REPO)/$(IMAGE_NAME)

%-supported:
	$(if $(findstring $*, $(TARGETS)),,$(error "$* not supported!"))

output-dir-%: %-supported
	@mkdir -p $(OUTPUT_DIR)/$*

ccache-dir:
	@mkdir -p $(CCACHE_DIR)

dl-dir:
	@mkdir -p $(DL_DIR)

%-clean: batocera-docker-image output-dir-%
	@$(DOCKER) run -it --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		-u $(UID):$(GID) \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make O=/$* BR2_EXTERNAL=/build -C /build/buildroot clean

%-config: output-dir-%
	@$(DOCKER) run -it --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		-u $(UID):$(GID) \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make O=/$* BR2_EXTERNAL=/build -C /build/buildroot mistex-$*_defconfig

%-build: %-config ccache-dir dl-dir
	@$(DOCKER) run -it --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v $(CCACHE_DIR):$(HOME)/.buildroot-ccache \
		-u $(UID):$(GID) \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make $(MAKE_OPTS) O=/$* BR2_EXTERNAL=/build -C /build/buildroot $(CMD)

%-shell: output-dir-% ccache-dir dl-dir
	@$(DOCKER) run -it --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-w /$* \
		-v $(CCACHE_DIR):$(HOME)/.buildroot-ccache \
		-u $(UID):$(GID) \
		$(DOCKER_OPTS) \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		$(CMD)

%-clean: output-dir-%
	@$(DOCKER) run -t --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		-u $(UID):$(GID) \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make O=/$* BR2_EXTERNAL=/build -C /build/buildroot clean

%-source: %-config ccache-dir dl-dir
	@$(DOCKER) run -it --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v $(CCACHE_DIR):$(HOME)/.buildroot-ccache \
		-u $(UID):$(GID) \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make $(MAKE_OPTS) O=/$* BR2_EXTERNAL=/build -C /build/buildroot source

%-pkg:
	$(if $(PKG),,$(error "PKG not specified!"))
	@$(MAKE) $*-build CMD=$(PKG)