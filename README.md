# Build custom docker image with additional modules

This project contains a Dockerfile that allows you to create a custom docker
image with any number of additional dynamic modules.

## Preconditions

Needs [yq](https://github.com/kislyuk/yq) installed.

## Building

To build a new docker image it's only necessary to provide the `modules` build
argument with a comma separated list of git repository URLs to be included in
the image as `remote_modules` and / or `with_modules` for nginx modules. Example:

```
git clone https://github.com/tsuru/docker-nginx-with-modules.git
cd docker-nginx-with-modules
docker build --build-arg with_modules=http_dav_module --build-arg remote_modules=https://github.com/vozlt/nginx-module-vts.git:v0.1.17,https://github.com/openresty/echo-nginx-module.git .
```

## Flavors

Flavors are a way to group a set of modules to generate a custom nginx image.
Flavors can be added by editing the `flavors.yaml` file and listing the module
URLs.

To build a flavor you can use the provided Makefile:

```
make image flavor=tsuru nginx_version=1.14.0
```
