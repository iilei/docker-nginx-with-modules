ARG nginx_version=1.15.9

FROM nginx:${nginx_version} as build

ARG remote_modules
ARG with_modules

RUN apt-get update \
    && apt-get install -y --no-install-suggests \
       libluajit-5.1-dev libpam0g-dev zlib1g-dev libpcre3-dev \
       libexpat1-dev git curl build-essential \
    && export NGINX_RAW_VERSION=$(echo $NGINX_VERSION | sed 's/-.*//g') \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_RAW_VERSION.tar.gz -o nginx.tar.gz \
    && tar -zxC /usr/src -f nginx.tar.gz

ARG remote_modules
ARG with_modules

RUN export NGINX_RAW_VERSION=$(echo $NGINX_VERSION | sed 's/-.*//g') \
    && cd /usr/src/nginx-$NGINX_RAW_VERSION \
    && configure_args="$(echo "$with_modules" | sed 's/,/ /') "; \
    IFS=','; \
    for module in ${remote_modules}; do \
        module_repo=$(echo $module | sed -E 's@^(((https?|git)://)?[^:]+).*@\1@g'); \
        module_tag=$(echo $module | sed -E 's@^(((https?|git)://)?[^:]+):?([^:/]*)@\4@g'); \
        dirname=$(echo "${module_repo}" | sed -E 's@^.*/|\..*$@@g'); \
        git clone "${module_repo}"; \
        cd ${dirname}; \
        if [ -n "${module_tag}" ]; then git checkout "${module_tag}"; fi; \
        cd ..; \
        configure_args="${configure_args} --add-dynamic-module=./${dirname}"; \
    done; unset IFS \
    && eval ./configure ${configure_args} --with-cc-opt="-DNGX_HTTP_HEADERS" \
    && make modules \
    && mkdir /modules \
    && cp $(pwd)/objs/*.so /modules

FROM nginx:${nginx_version}
COPY --from=build /modules/* /etc/nginx/modules/

# list all installed modules
RUN 2>&1 ls -A /etc/nginx/modules/ | awk 'NF{ print $NF }'

# TODO:
# loop over the list and add
# load_module "modules/<module name>";
# to /etc/nginx/nginx.conf just before the first occurence of \n\S+\s*\{ (i.e.: "<LF>events {"

