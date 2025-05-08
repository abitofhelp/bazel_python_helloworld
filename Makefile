include scripts/bazel/version.bzl
# The imported version includes the quote characters, so they are removed.
CLNVERSION=$(shell echo $(VERSION))

# The previous version that exists in deployment scripts and MODULE.bazel.
# TODO: THIS MUST BE MANUALLY SET AT THIS TIME!
PREVVERSION=v5.6.0

PROJECT_NAME=falcon
CLIENT_DIR=github.com/ingios/$(PROJECT_NAME)
MODULE_NAME=$(CLIENT_DIR)/v5
PROJECT_DIR=$(GOPATH)/src/$(CLIENT_DIR)

BZL_CMD=bazel
BAZEL_BUILD_OPTS:=
BAZEL_BUILD_OPTS_DARWIN:=   $(BAZEL_BUILD_OPTS) --platforms=@rules_go//go/toolchain:darwin_amd64
BAZEL_BUILD_OPTS_LINUX:=	$(BAZEL_BUILD_OPTS) --platforms=@rules_go//go/toolchain:linux_amd64
BAZEL_BUILD_OPTS_WINDOWS:=	$(BAZEL_BUILD_OPTS) --platforms=@rules_go//go/toolchain:windows_amd64
BAZEL_BUILD_OPTS_OCI:=$(BAZEL_BUILD_OPTS_LINUX)
CP_CMD=cp -f
DOCKER_CMD=docker
DOCKER_COMPOSE_CMD=docker-compose
GO_CMD=$(BZL_CMD) run @rules_go//go
INGIOS_CONTAINER_REGISTRY?=d3falcon.azurecr.io
PKG_DIR=$(PROJECT_DIR)/pkg
RM_CMD=rm -f
SERVICE_DIR=$(PROJECT_DIR)/service
CMD_DIR=$(PROJECT_DIR)/cmd

# LIBRARIES/PACKAGES
ALERT_LIB_DIR=$(PKG_DIR)/alert
ALERT_LIB_WORKSPACE=//pkg/alert
ALERT_LIB_TARGET=//pkg/alert:alert

CSCLIBRARY_LIB_DIR=$(PKG_DIR)/csclibrary
CSCLIBRARY_LIB_WORKSPACE=//pkg/csclibrary
CSCLIBRARY_LIB_TARGET=//pkg/csclibrary:csclibrary

GOLIBRARY_LIB_DIR=$(PKG_DIR)/golibrary
GOLIBRARY_LIB_WORKSPACE=//pkg/golibrary
GOLIBRARY_LIB_TARGET=//pkg/golibrary:golibrary

# COMMAND LINE ADMIN APPS
COMMITTER_CMD_TARGET=//cmd/committer:committer
COMMITTER_CMD_TARGET_DARWIN_AMD64=//cmd/committer:committer_darwin_amd64
COMMITTER_CMD_TARGET_LINUX_AMD64=//cmd/committer:committer_linux_amd64
COMMITTER_CMD_TARGET_WINDOWS_AMD64=//cmd/committer:committer_windows_amd64
COMMITTER_CMD_DIR=$(CMD_DIR)/committer
COMMITTER_CMD_WORKSPACE=//cmd/committer

# FALCON'S BACKEND SERVICES
BLOB_PROXY_TARGET=//service/blob/proxy:blob_proxy
BLOB_SERVER_TARGET=//service/blob/server:blob_server
BLOB_SERVICE_DIR=$(SERVICE_DIR)/blob
BLOB_SERVICE_NAME=blob_service
BLOB_SERVICE_PROXY_NAME=$(BLOB_SERVICE_NAME)_proxy
BLOB_SERVICE_WORKSPACE=//service/blob

PROJECT_PROXY_TARGET=//service/project/proxy:project_proxy
PROJECT_SERVER_TARGET=//service/project/server:project_server
PROJECT_SERVICE_DIR=$(SERVICE_DIR)/project
PROJECT_SERVICE_NAME=project_service
PROJECT_SERVICE_PROXY_NAME=$(PROJECT_SERVICE_NAME)_proxy
PROJECT_SERVICE_WORKSPACE=//service/project

QUEUE_PROXY_TARGET=//service/queue/proxy:queue_proxy
QUEUE_SERVER_TARGET=//service/queue/server:queue_server
QUEUE_SERVICE_DIR=$(SERVICE_DIR)/queue
QUEUE_SERVICE_NAME=queue_service
QUEUE_SERVICE_PROXY_NAME=$(QUEUE_SERVICE_NAME)_proxy
QUEUE_SERVICE_WORKSPACE=//service/queue

RUN_PROXY_TARGET=//service/run/proxy:run_proxy
RUN_SERVER_TARGET=//service/run/server:run_server
RUN_SERVICE_DIR=$(SERVICE_DIR)/run
RUN_SERVICE_NAME=run_service
RUN_SERVICE_PROXY_NAME=$(RUN_SERVICE_NAME)_proxy
RUN_SERVICE_WORKSPACE=//service/run

SLIDERMAP_PROXY_TARGET=//service/slidermap/proxy:slidermap_proxy
SLIDERMAP_SERVER_TARGET=//service/slidermap/server:slidermap_server
SLIDERMAP_SERVICE_DIR=$(SERVICE_DIR)/slidermap
SLIDERMAP_SERVICE_NAME=slidermap_service
SLIDERMAP_SERVICE_PROXY_NAME=$(SLIDERMAP_SERVICE_NAME)_proxy
SLIDERMAP_SERVICE_WORKSPACE=//service/slidermap

TRACK_PROXY_TARGET=//service/track/proxy:track_proxy
TRACK_SERVER_TARGET=//service/track/server:track_server
TRACK_SERVICE_DIR=$(SERVICE_DIR)/track
TRACK_SERVICE_NAME=track_service
TRACK_SERVICE_PROXY_NAME=$(TRACK_SERVICE_NAME)_proxy
TRACK_SERVICE_WORKSPACE=//service/track

build_ALL: build_ALL_PLATFORMS_committer build_ALL_oci_images

make_release: deep_clean_bazel configure_release_build build_ALL tag_ALL_for_ingios export_ALL_oci_images pub_ALL_to_acr configure_dev_build update_deployment_scripts

update_deployment_scripts:
	# MacOS permits an empty backup file extension after "-i" to indicate that no backup file will be created.
	# On Linux, the "-i "" is deleted from the command.
	sed -i '' 's/$PREVVERSION/$(CLNVERSION)/g' MODULE.bazel
	sed -i '' 's/image: d3falcon.azurecr.io\/blob_service_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/blob_service_linux_amd64:$(CLNVERSION)/g' service/blob/deployment/blob-service.*.yml
	sed -i '' 's/image: d3falcon.azurecr.io\/project_service_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/project_service_linux_amd64:$(CLNVERSION)/g' service/project/deployment/project-service.*.yml
	sed -i '' 's/image: d3falcon.azurecr.io\/queue_service_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/queue_service_linux_amd64:$(CLNVERSION)/g' service/queue/deployment/queue-service.*.yml
	sed -i '' 's/image: d3falcon.azurecr.io\/run_service_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/run_service_linux_amd64:$(CLNVERSION)/g' service/run/deployment/run-service.*.yml
	sed -i '' 's/image: d3falcon.azurecr.io\/slidermap_service_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/slidermap_service_linux_amd64:$(CLNVERSION)/g' service/slidermap/deployment/slidermap-service.*.yml
	sed -i '' 's/image: d3falcon.azurecr.io\/track_service_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/track_service_linux_amd64:$(CLNVERSION)/g' service/track/deployment/track-service.*.yml

	sed -i '' 's/image: d3falcon.azurecr.io\/blob_service_proxy_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/blob_service_proxy_linux_amd64:$(CLNVERSION)/g' service/blob/deployment/blob-service.*.yml
	sed -i '' 's/image: d3falcon.azurecr.io\/project_service_proxy_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/project_service_proxy_linux_amd64:$(CLNVERSION)/g' service/project/deployment/project-service.*.yml
	sed -i '' 's/image: d3falcon.azurecr.io\/queue_service_proxy_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/queue_service_proxy_linux_amd64:$(CLNVERSION)/g' service/queue/deployment/queue-service.*.yml
	sed -i '' 's/image: d3falcon.azurecr.io\/run_service_proxy_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/run_service_proxy_linux_amd64:$(CLNVERSION)/g' service/run/deployment/run-service.*.yml
	sed -i '' 's/image: d3falcon.azurecr.io\/slidermap_service_proxy_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/slidermap_service_proxy_linux_amd64:$(CLNVERSION)/g' service/slidermap/deployment/slidermap-service.*.yml
	sed -i '' 's/image: d3falcon.azurecr.io\/track_service_proxy_linux_amd64:v$PREVVERSION/image: d3falcon.azurecr.io\/track_service_proxy_linux_amd64:$(CLNVERSION)/g' service/track/deployment/track-service.*.yml

build_alert_lib:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(ALERT_LIB_TARGET)

build_blob_proxy:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(BLOB_PROXY_TARGET)

build_blob_server:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(BLOB_SERVER_TARGET)

build_committer:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(COMMITTER_CMD_TARGET)

build_ALL_PLATFORMS_committer: build_committer_linux build_committer_darwin build_committer_windows

build_committer_linux:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS_LINUX) $(COMMITTER_CMD_TARGET_LINUX_AMD64)
	$(CP_CMD) bazel-bin/cmd/committer/committer_linux_amd64_/committer_linux_amd64   "$(PROJECT_DIR)/committer_linux_amd64_$(CLNVERSION)"
	pushd $(PROJECT_DIR) && \
	tar -cvzf "committer_linux_amd64_$(CLNVERSION).tar.gz" "committer_linux_amd64_$(CLNVERSION)" && \
	$(RM_CMD) "committer_linux_amd64_$(CLNVERSION)" && \
	popd;

build_committer_darwin:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS_DARWIN) $(COMMITTER_CMD_TARGET_DARWIN_AMD64)
	$(CP_CMD)  bazel-bin/cmd/committer/committer_darwin_amd64_/committer_darwin_amd64   "$(PROJECT_DIR)/committer_darwin_amd64_$(CLNVERSION)"
	pushd $(PROJECT_DIR) && \
	tar -cvzf "committer_darwin_amd64_$(CLNVERSION).tar.gz" "committer_darwin_amd64_$(CLNVERSION)" && \
	$(RM_CMD) "committer_darwin_amd64_$(CLNVERSION)" && \
	popd;

build_committer_windows:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS_WINDOWS) $(COMMITTER_CMD_TARGET_WINDOWS_AMD64)
	$(CP_CMD)  bazel-bin/cmd/committer/committer_windows_amd64_/committer_windows_amd64.exe   "$(PROJECT_DIR)/committer_windows_amd64_$(CLNVERSION).exe"
	pushd $(PROJECT_DIR) && \
	tar -cvzf "committer_windows_amd64_$(CLNVERSION).tar.gz" "committer_windows_amd64_$(CLNVERSION).exe" && \
	$(RM_CMD) "committer_windows_amd64_$(CLNVERSION).exe" && \
	popd;

build_csclibrary_lib:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(CSCLIBRARY_LIB_TARGET)

build_golibrary_lib:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(GOLIBRARY_LIB_TARGET)

build_project_proxy:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(PROJECT_PROXY_TARGET)

build_project_server:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(PROJECT_SERVER_TARGET)

build_queue_proxy:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(QUEUE_PROXY_TARGET)

build_queue_server:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(QUEUE_SERVER_TARGET)

build_run_proxy:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(RUN_PROXY_TARGET)

build_run_server:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(RUN_SERVER_TARGET)

build_slidermap_proxy:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(SLIDERMAP_PROXY_TARGET)

build_slidermap_server:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(SLIDERMAP_SERVER_TARGET)

build_track_proxy:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(TRACK_PROXY_TARGET)

build_track_server:
	$(BZL_CMD) build $(BAZEL_BUILD_OPTS) $(TRACK_SERVER_TARGET)

build_ALL_oci_images: build_blob_server_oci_image build_blob_proxy_oci_image build_project_server_oci_image build_project_proxy_oci_image build_queue_server_oci_image build_queue_proxy_oci_image build_run_server_oci_image build_run_proxy_oci_image build_slidermap_server_oci_image build_slidermap_proxy_oci_image  build_track_server_oci_image build_track_proxy_oci_image

build_blob_proxy_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/blob/proxy:blob_proxy_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/blob/proxy:blob_proxy_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\

build_blob_server_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/blob/server:blob_server_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/blob/server:blob_server_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\
	
build_project_proxy_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/project/proxy:project_proxy_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/project/proxy:project_proxy_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\

build_project_server_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/project/server:project_server_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/project/server:project_server_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\

build_queue_proxy_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/queue/proxy:queue_proxy_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/queue/proxy:queue_proxy_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\

build_queue_server_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/queue/server:queue_server_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/queue/server:queue_server_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\

build_run_proxy_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/run/proxy:run_proxy_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/run/proxy:run_proxy_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\

build_run_server_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/run/server:run_server_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/run/server:run_server_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\

build_slidermap_proxy_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/slidermap/proxy:slidermap_proxy_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/slidermap/proxy:slidermap_proxy_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\

build_slidermap_server_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/slidermap/server:slidermap_server_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/slidermap/server:slidermap_server_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\

build_track_proxy_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/track/proxy:track_proxy_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/track/proxy:track_proxy_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\

build_track_server_oci_image:
	set -e ;\
	bazel build ${BAZEL_BUILD_OPTS_OCI} //service/track/server:track_server_tarball ;\
	TARBALL=$$(bazel cquery --output=files //service/track/server:track_server_tarball) ;\
	docker load --input $$(realpath $$TARBALL) ;\

buildifier_check:
	$(BZL_CMD) run //:buildifier.check

clean_bazel:
	# Removes bazel-created output, including all object files, and bazel metadata.
	pushd $(PROJECT_DIR) && \
	$(BZL_CMD) clean --async && \
	popd;

clean_vendors:
	pushd $(PROJECT_DIR) && \
	find . -path '*/vendor*' -delete && \
	popd;

configure_dev_build:
	# MacOS permits an empty backup file extension after "-i" to indicate that no backup file will be created.
	# On Linux, the "-i "" is deleted from the command.
	sed -i '' 's/#build --workspace_status_command/build --workspace_status_command/g' .bazelrc

configure_release_build:
	# MacOS permits an empty backup file extension after "-i" to indicate that no backup file will be created.
	# On Linux, the "-i "" is deleted from the command.
	sed -i '' 's/build --workspace_status_command/#build --workspace_status_command/g' .bazelrc

deep_clean_bazel:
	# Removes bazel-created output, including all object files, and bazel metadata.
	pushd $(PROJECT_DIR) && \
	$(BZL_CMD) clean --expunge --async && \
	popd;

delete_images_for_version:
	# Determine the ID values for the images and delete them.
	docker rmi --force $$(docker images --format {{.Repository}}:{{.Tag}}@{{.ID}} |grep $(CLNVERSION) |awk '{split($$0, array, "@"); print array[2]}' |sort -u |awk '{print $1}')

expand_golang_build:
	$(BZL_CMD) query $(GOLIBRARY_LIB_TARGET) --output=build

export_ALL_oci_images:
	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(BLOB_SERVICE_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(BLOB_SERVICE_NAME)_linux_amd64_$(CLNVERSION).tar.gz"
	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(BLOB_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(BLOB_SERVICE_PROXY_NAME)_linux_amd64_$(CLNVERSION).tar.gz"

	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(PROJECT_SERVICE_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(PROJECT_SERVICE_NAME)_linux_amd64_$(CLNVERSION).tar.gz"
	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(PROJECT_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(PROJECT_SERVICE_PROXY_NAME)_linux_amd64_$(CLNVERSION).tar.gz"

	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(QUEUE_SERVICE_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(QUEUE_SERVICE_NAME)_linux_amd64_$(CLNVERSION).tar.gz"
	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(QUEUE_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(QUEUE_SERVICE_PROXY_NAME)_linux_amd64_$(CLNVERSION).tar.gz"

	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(RUN_SERVICE_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(RUN_SERVICE_NAME)_linux_amd64_$(CLNVERSION).tar.gz"
	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(RUN_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(RUN_SERVICE_PROXY_NAME)_linux_amd64_$(CLNVERSION).tar.gz"

	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(SLIDERMAP_SERVICE_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(SLIDERMAP_SERVICE_NAME)_linux_amd64_$(CLNVERSION).tar.gz"
	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(SLIDERMAP_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(SLIDERMAP_SERVICE_PROXY_NAME)_linux_amd64_$(CLNVERSION).tar.gz"

	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(TRACK_SERVICE_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(TRACK_SERVICE_NAME)_linux_amd64_$(CLNVERSION).tar.gz"
	docker save "$(INGIOS_CONTAINER_REGISTRY)/$(TRACK_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)" | gzip > "$(INGIOS_CONTAINER_REGISTRY)_$(TRACK_SERVICE_PROXY_NAME)_linux_amd64_$(CLNVERSION).tar.gz"


gazelle_generate:
	# Alternative using go rather than bazel: gazelle update -go_prefix github.com/ingios/falcon/v5
	pushd $(PROJECT_DIR) && \
	$(BZL_CMD) run $(BAZEL_BUILD_OPTS) //:gazelle && \
	popd;

gen_cp_files_to_src:
	pushd $(PROJECT_DIR) && \
	sudo -S ./scripts/shell/cp_gen_files.bsh && \
	popd;

gen_files:
	$(BZL_CMD) build //pkg/ingiosapis/proto/...

gen_refresh_files: gen_rm_files gen_files gen_cp_files_to_src

gen_rm_files:
	 find pkg/ingiosapis -type f -name "*.go" -delete
	
generate_csclibrary_deps_graph:
	pushd $(PROJECT_DIR) && \
	$(BZL_CMD) query --notool_deps --noimplicit_deps "deps(//pkg/csclibrary:csclibrary)" --output graph && \
	dot -Tsvg graph.dot > csclibrary_graph.svg && \
	popd;

go_mod_download:
	pushd $(PROJECT_DIR) && \
	$(GO_CMD) -- mod download && \
	popd;

go_mod_tidy:
	pushd $(PROJECT_DIR) && \
	$(GO_CMD) -- mod tidy && \
	popd;
	
go_mod_upgrade_dependencies:
	pushd $(PROJECT_DIR) && \
	$(GO_CMD) -- get -u ./... && \
	popd;

go_mod_vendor:
	pushd $(PROJECT_DIR) && \
	$(GO_CMD) -- mod vendor -v && \
	popd;

go_mod_verify:
	## Verify that the go.sum file matches what was downloaded to prevent someone “git push — force” over a tag being used.
	pushd $(PROJECT_DIR) && \
	$(GO_CMD) -- mod verify && \
	popd;

go_targets:
	$(BZL_CMD) query "@rules_go//go:*"

go_vulnerability_check:
	pushd $(PROJECT_DIR) && \
	govulncheck ./... &&\
	popd;

list_ALL_targets:
	$(BZL_CMD) query "//..."

list_alias_targets:
	$(BZL_CMD) query "kind(alias, //...)"

list_ALL_images_for_version:
	docker images | grep $(CLNVERSION) |sort |awk '{print $3}'

list_ALL_platforms:
	$(BZL_CMD)  query 'kind(platform, @rules_go//go/toolchain:all)'

pub_blob_to_acr:
	@az acr login --name d3falcon
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(BLOB_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(BLOB_SERVICE_NAME)_linux_amd64:latest"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(BLOB_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(BLOB_SERVICE_PROXY_NAME)_linux_amd64:latest"

pub_project_to_acr:
	@az acr login --name d3falcon
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(PROJECT_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(PROJECT_SERVICE_NAME)_linux_amd64:latest"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(PROJECT_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(PROJECT_SERVICE_PROXY_NAME)_linux_amd64:latest"

pub_queue_to_acr:
	@az acr login --name d3falcon
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(QUEUE_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(QUEUE_SERVICE_NAME)_linux_amd64:latest"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(QUEUE_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(QUEUE_SERVICE_PROXY_NAME)_linux_amd64:latest"

pub_run_to_acr:
	@az acr login --name d3falcon
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(RUN_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(RUN_SERVICE_NAME)_linux_amd64:latest"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(RUN_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(RUN_SERVICE_PROXY_NAME)_linux_amd64:latest"

pub_slidermap_to_acr:
	@az acr login --name d3falcon
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(SLIDERMAP_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(SLIDERMAP_SERVICE_NAME)_linux_amd64:latest"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(SLIDERMAP_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(SLIDERMAP_SERVICE_PROXY_NAME)_linux_amd64:latest"

pub_track_to_acr:
	@az acr login --name d3falcon
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(TRACK_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(TRACK_SERVICE_NAME)_linux_amd64:latest"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(TRACK_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	docker push "$(INGIOS_CONTAINER_REGISTRY)/$(TRACK_SERVICE_PROXY_NAME)_linux_amd64:latest"

pub_ALL_to_acr: pub_blob_to_acr pub_project_to_acr pub_queue_to_acr pub_run_to_acr pub_slidermap_to_acr pub_track_to_acr

run_project_proxy_binary::)

	# Must be a native binary build not an OCI container.
	$(BZL_CMD) run $(PROJECT_PROXY_TARGET)

set_golang_version:
	sed -E -i '.org' 's/go 1.21.3/go 1.21.4/g' "$(PROJECT_DIR)/go.mod" && $(RM_CMD) "$(PROJECT_DIR)/go.mod.org" && \
	sed -E -i '.org' 's/go_sdk.download(version = "1.21.3")"/go_sdk.download(version = "1.21.4")/g' "$(PROJECT_DIR)/MODULE.bazel" && $(RM_CMD) "$(PROJECT_DIR)/MODULE.bazel.org" ;

show_version:
	@echo $(CLNVERSION)

start_ALL_containers: build_ALL_oci_images
	pushd $(PROJECT_DIR) && \
	$(DOCKER_COMPOSE_CMD) up && \
	popd;

stop_ALL_containers:
	pushd $(PROJECT_DIR) && \
	$(DOCKER_COMPOSE_CMD) down && \
	popd;

start_blob_and_proxy_containers: build_blob_server_oci_image build_blob_proxy_oci_image
	pushd $(BLOB_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) up && \
	popd;

stop_blob_and_proxy_containers:
	pushd $(BLOB_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) down && \
	popd;

start_project_and_proxy_containers: build_project_server_oci_image build_project_proxy_oci_image
	pushd $(PROJECT_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) up && \
	popd;

stop_project_and_proxy_containers:
	pushd $(PROJECT_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) down && \
	popd;

start_queue_and_proxy_containers: build_queue_server_oci_image build_queue_proxy_oci_image
	pushd $(QUEUE_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) up && \
	popd;

stop_queue_and_proxy_containers:
	pushd $(QUEUE_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) down && \
	popd;
	
start_run_and_proxy_containers: build_run_server_oci_image build_run_proxy_oci_image
	pushd $(RUN_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) up && \
	popd;

stop_run_and_proxy_containers:
	pushd $(RUN_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) down && \
	popd;

start_slidermap_and_proxy_containers: build_slidermap_server_oci_image build_slidermap_proxy_oci_image
	pushd $(SLIDERMAP_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) up && \
	popd;

stop_slidermap_and_proxy_containers:
	pushd $(SLIDERMAP_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) down && \
	popd;
	
start_track_and_proxy_containers: build_track_server_oci_image build_track_proxy_oci_image
	pushd $(TRACK_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) up && \
	popd;

stop_track_and_proxy_containers:
	pushd $(TRACK_SERVICE_DIR) && \
	$(DOCKER_COMPOSE_CMD) down && \
	popd;

sync_from_gomod: go_mod_download go_mod_tidy go_mod_verify gazelle_generate

tag_for_ingios_blob:
	@docker tag "$(BLOB_SERVICE_NAME)_linux_amd64:latest" 			"$(INGIOS_CONTAINER_REGISTRY)/$(BLOB_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(BLOB_SERVICE_NAME)_linux_amd64:latest" 			"$(INGIOS_CONTAINER_REGISTRY)/$(BLOB_SERVICE_NAME)_linux_amd64:latest"
	@docker tag "$(BLOB_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(BLOB_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(BLOB_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(BLOB_SERVICE_PROXY_NAME)_linux_amd64:latest"

tag_for_ingios_project:
	@docker tag "$(PROJECT_SERVICE_NAME)_linux_amd64:latest" 			"$(INGIOS_CONTAINER_REGISTRY)/$(PROJECT_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(PROJECT_SERVICE_NAME)_linux_amd64:latest" 			"$(INGIOS_CONTAINER_REGISTRY)/$(PROJECT_SERVICE_NAME)_linux_amd64:latest"
	@docker tag "$(PROJECT_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(PROJECT_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(PROJECT_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(PROJECT_SERVICE_PROXY_NAME)_linux_amd64:latest"

tag_for_ingios_queue:
	@docker tag "$(QUEUE_SERVICE_NAME)_linux_amd64:latest" 		"$(INGIOS_CONTAINER_REGISTRY)/$(QUEUE_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(QUEUE_SERVICE_NAME)_linux_amd64:latest" 		"$(INGIOS_CONTAINER_REGISTRY)/$(QUEUE_SERVICE_NAME)_linux_amd64:latest"
	@docker tag "$(QUEUE_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(QUEUE_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(QUEUE_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(QUEUE_SERVICE_PROXY_NAME)_linux_amd64:latest"

tag_for_ingios_run:
	@docker tag "$(RUN_SERVICE_NAME)_linux_amd64:latest" 			"$(INGIOS_CONTAINER_REGISTRY)/$(RUN_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(RUN_SERVICE_NAME)_linux_amd64:latest" 			"$(INGIOS_CONTAINER_REGISTRY)/$(RUN_SERVICE_NAME)_linux_amd64:latest"
	@docker tag "$(RUN_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(RUN_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(RUN_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(RUN_SERVICE_PROXY_NAME)_linux_amd64:latest"

tag_for_ingios_slidermap:
	@docker tag "$(SLIDERMAP_SERVICE_NAME)_linux_amd64:latest" 		"$(INGIOS_CONTAINER_REGISTRY)/$(SLIDERMAP_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(SLIDERMAP_SERVICE_NAME)_linux_amd64:latest" 		"$(INGIOS_CONTAINER_REGISTRY)/$(SLIDERMAP_SERVICE_NAME)_linux_amd64:latest"
	@docker tag "$(SLIDERMAP_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(SLIDERMAP_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(SLIDERMAP_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(SLIDERMAP_SERVICE_PROXY_NAME)_linux_amd64:latest"

tag_for_ingios_track:
	@docker tag "$(TRACK_SERVICE_NAME)_linux_amd64:latest" 		"$(INGIOS_CONTAINER_REGISTRY)/$(TRACK_SERVICE_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(TRACK_SERVICE_NAME)_linux_amd64:latest" 		"$(INGIOS_CONTAINER_REGISTRY)/$(TRACK_SERVICE_NAME)_linux_amd64:latest"
	@docker tag "$(TRACK_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(TRACK_SERVICE_PROXY_NAME)_linux_amd64:$(CLNVERSION)"
	@docker tag "$(TRACK_SERVICE_PROXY_NAME)_linux_amd64:latest" 	"$(INGIOS_CONTAINER_REGISTRY)/$(TRACK_SERVICE_PROXY_NAME)_linux_amd64:latest"

tag_ALL_for_ingios: tag_for_ingios_blob tag_for_ingios_project tag_for_ingios_queue tag_for_ingios_run tag_for_ingios_slidermap tag_for_ingios_track

tidy: clean_bazel clean_vendors go_mod_tidy go_mod_verify


zap: deep_clean_bazel clean_vendors
	pushd $(PROJECT_DIR) && \
	find . -type f -name "go.sum" -delete && \
	go clean -modcache -cache && \
	make go_mod_download && \
	make go_mod_tidy && \
	make go_mod_vendor && \
	make go_mod_verify && \
	popd;

