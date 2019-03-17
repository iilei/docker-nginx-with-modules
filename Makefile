nginx_version ?= 1.14.2

all:
	flavors=$$(yq -er '.flavors[].name' flavors.yaml) && \
	for f in $$flavors; do make flavor=$$f image; done

image:
	with_modules=$$(yq -er '.flavors[] | select(.name == "$(flavor)") | .modules | map(select(.|test("^[^:]+$$"; "i"))) | map(. |= "--with-" + .) | join(",")' flavors.yaml) && \
	remote_modules=$$(yq -er '.flavors[] | select(.name == "$(flavor)") | .modules | map(select(.|test("^[^:]+:"; "i"))) | join(",")' flavors.yaml) && \
	docker build -t nginx-$(flavor):$(nginx_version) \
		--build-arg nginx_version=$(nginx_version) \
		--build-arg with_modules="$$with_modules" \
		--build-arg remote_modules="$$remote_modules" \
		.

.PHONY: all flavor
