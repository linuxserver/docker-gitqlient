FROM ghcr.io/linuxserver/baseimage-alpine:3.22 AS buildstage

ARG GITQLIENT_RELEASE

RUN \
  echo "**** install build deps ****" && \
  apk add --no-cache \
    alpine-sdk \
    cmake \
    qt5-qtbase-dev 

RUN \
  echo "**** grab source ****" && \
  git clone https://github.com/francescmm/GitQlient.git

RUN \
  echo "**** build gitqclient ****" && \
  mkdir -p /build-out/usr && \
  if [ -z ${GITQLIENT_RELEASE+x} ]; then \
    GITQLIENT_RELEASE=$(curl -sX GET "https://api.github.com/repos/francescmm/GitQlient/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  cd /GitQlient && \
  qmake-qt5 GitQlient.pro \
    PREFIX=/build-out/usr \
    VERSION=${GITQLIENT_RELEASE:1} && \
  make -j 4 && \
  make install

FROM ghcr.io/linuxserver/baseimage-selkies:alpine322

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# title
ENV TITLE=GitQlient

COPY --from=buildstage /build-out/ /

RUN \
  echo "**** add icon ****" && \
  curl -o \
    /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/gitqlient-icon.png && \
  echo "**** install packages ****" && \
  apk add --no-cache \
    git \
    openssh-askpass \
    qt5-qtbase-x11 \
    qt5-qtsvg \
    thunar && \
  echo "**** app tweaks ****" && \
  ln -s \
    /usr/lib/ssh/gtk-ssh-askpass \
    /usr/bin/ssh-askpass && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3000

VOLUME /config
