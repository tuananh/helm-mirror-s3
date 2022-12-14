ARCH := $(shell uname -m)
KEY ?= local-melange.rsa
PACKAGE ?= packages/${ARCH}/helm-mirror-*.apk

MELANGE_OPTS += --keyring-append ${KEY}.pub
MELANGE_OPTS += --signing-key ${KEY}
MELANGE_OPTS += --arch x86_64

dev-container:
	docker run --privileged --rm -it -v "${PWD}:${PWD}" -w "${PWD}" cgr.dev/chainguard/sdk

${KEY}:
	docker run --privileged --rm --entrypoint melange -v "${PWD}:${PWD}" -w "${PWD}" cgr.dev/chainguard/sdk keygen ${KEY}

${PACKAGE}: ${KEY}
	docker run --privileged --rm --entrypoint melange -v "${PWD}:${PWD}" -w "${PWD}" cgr.dev/chainguard/sdk build melange.yaml ${MELANGE_OPTS}

image: ${PACKAGE}
	docker run --privileged --rm --entrypoint apko -v "${PWD}:${PWD}" -w "${PWD}" cgr.dev/chainguard/sdk build --keyring-append local-melange.rsa.pub apko.yaml helm-mirror:latest helm-mirror.tar