nginx_version ?= 1.15.9

all:
	flavors=$$(jq -er '.flavors[].name' flavors.json) && \
	for f in $$flavors; do make flavor=$$f image; done

image:
	modules=$$(jq -er '.flavors[] | select(.name == "$(flavor)") | .modules | join(",")' flavors.json) && \
	configure_args=$$(jq -er '.flavors[] | select(.name == "$(flavor)") | .configure_args | join(" ")' flavors.json) && \
	docker build -t nginx-$(flavor):$(nginx_version) \
		--build-arg nginx_version=$(nginx_version) \
		--build-arg configure_args="$$configure_args" \
		--build-arg modules="$$modules" .

.PHONY: all flavor
