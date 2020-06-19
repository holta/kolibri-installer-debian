FROM python:3-alpine as make_dist

RUN apk update && apk add \
    make \
    bash \
    tar

# If build_src is alredy present, shouldn't need to redownload
COPY build_src/ build_src/
COPY Makefile .

RUN make clean && make dist/kolibri_archive.tar.gz dist/VERSION


FROM ubuntu:bionic

# Fetch some additional build requirements
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      adduser \
      build-essential \
      devscripts \
      dirmngr \
      fakeroot \
      software-properties-common

# Use the published kolibri-proposed PPA
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AD405B4A && \
    add-apt-repository -y -u -s ppa:learningequality/kolibri-proposed

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y build-dep kolibri

RUN adduser --system --shell /bin/bash --home "/kolibribuild" kolibribuild && \
    cd /kolibribuild && \
    apt-get update && \
    su kolibribuild -c "apt-get -y source kolibri"

# Build an unsigned package

WORKDIR /kolibribuild

COPY --from=make_dist Makefile .
COPY --from=make_dist dist dist
COPY --from=make_dist build_src build_src
COPY build_tools build_tools
COPY debian debian



ENTRYPOINT [ "make" ]

CMD [ "dist/kolibri.deb" ]
