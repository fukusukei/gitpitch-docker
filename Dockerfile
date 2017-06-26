FROM openjdk:jdk-alpine

ENV ALPINE_CDN_URL "http://dl-cdn.alpinelinux.org"

ENV LANG C.UTF-8

ENV GITPICH_GITVERSION v1.1.0
ENV GITPICH_ZIPVERSION 1.1
# sbt setting
ENV SBT_VERSION 0.13.15 
ENV SBT_HOME /usr/local/sbt 
ENV PATH ${PATH}:${SBT_HOME}/bin

WORKDIR workspace

# RUN START 
RUN apk add --no-cache --update-cache \
        shadow \
        ca-certificates \
        bash \
        openssl && \
# downloading build dependencies,
# downloading and unpacking the distribution, changing file permissions, removing bundled JVMs,
# removing build dependencies
    apk add -q --no-cache --virtual \ 
        build-dependencies \
        wget \
        unzip \
        git \
        openssh && \
    mkdir -p "$SBT_HOME" && \
 # downloading sbt.     
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub && \
    wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-2.25-r0.apk && apk add glibc-2.25-r0.apk && \
    wget -qO - --no-check-certificate "https://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz" | tar xz -C $SBT_HOME --strip-components=1 && \
 # sbt build carry out subsequently clone gitpitch fom GitHub.
 # If you are behind a proxy, you need to set proxy setting.
    git clone https://github.com/gitpitch/gitpitch.git && \
    cd gitpitch && \
    git checkout -b local_${GITPICH_GITVERSION} ${GITPICH_GITVERSION} && \
    sbt dist && \
    echo -ne "- with sbt $SBT_VERSION\n" >> /root/.built && \
    unzip target/universal/server-${GITPICH_ZIPVERSION}.zip -d /opt/ && \
    cd .. && \
    rm -rf workspace/gitpitch/ && \
    mv /opt/server-${GITPICH_ZIPVERSION} /opt/gitpitch && \
    apk del --purge -r build-dependencies
# RUN END

CMD ["/opt/gitpitch/bin/server","-Dconfig.file=/opt/gitpitch/custom/production.conf"]