ARG nginx_version=1.14.2

# 1.15.9 ?

FROM nginx:${nginx_version} as build

RUN apt-get update \
    && apt-get install -y --no-install-suggests \
        libperl-dev libgeoip-dev libgd-dev \
        nginx-full \
        libluajit-5.1-dev libpam0g-dev zlib1g-dev libpcre3-dev \
        libexpat1-dev git curl build-essential \
        libc-dev libxml2 libxslt-dev \
    && export NGINX_RAW_VERSION=$(echo $NGINX_VERSION | sed 's/-.*//g') \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_RAW_VERSION.tar.gz -o nginx.tar.gz \
    && tar -zxC /usr/src -f nginx.tar.gz

ARG remote_modules
ARG with_modules

RUN export NGINX_RAW_VERSION=$(echo $NGINX_VERSION | sed 's/-.*//g') \
    && cd /usr/src/nginx-$NGINX_RAW_VERSION \
    && configure_args="$(echo "$with_modules" | sed 's/,/ /')"; \
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
    && eval ./configure ${configure_args} \
    && make modules \
    && mkdir /modules \
    && cp $(pwd)/objs/*.so /modules

FROM nginx:${nginx_version}
COPY --from=build /modules/* /etc/nginx/modules/
CMD nginx -T
