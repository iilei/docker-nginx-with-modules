nginx_version ?= 1.14.0

all:
	flavors=$$(jq -er '.flavors[].name' flavors.json) && \
	for f in $$flavors; do make flavor=$$f image; done

image:
	with_modules=$$(jq -er '.flavors[] | select(.name == "$(flavor)") | .modules | map(select(.|test("^[^:]+$$"; "i"))) | map(. |= "--with-" + .) | join(",")' flavors.json) && \
	remote_modules=$$(jq -er '.flavors[] | select(.name == "$(flavor)") | .modules | map(select(.|test("^[^:]+:"; "i"))) | join(",")' flavors.json) && \
	docker build -t nginx-$(flavor):$(nginx_version) \
		--build-arg nginx_version=$(nginx_version) \
		--build-arg with_modules="$$with_modules" \
		--build-arg remote_modules="$$remote_modules" \
		.

.PHONY: all flavor
