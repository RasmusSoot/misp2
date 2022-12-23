FROM ubuntu:18.04
RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get -qq update \
  && apt-get -qq upgrade \
  && apt-get install apt-transport-https curl gnupg -yqq \
  && echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list \
  && echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list \
  && curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import \
  && chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg \
  && apt-get update \
  && apt-get -qq install openjdk-8-jdk openjdk-8-jre sbt locales git nodejs \
  && locale-gen en_US.UTF-8 \
  && update-locale "LANG=en_US.UTF-8" \
  && apt-get -qq autoremove \
  && apt-get -qq clean

ARG uid
ARG gid

RUN groupadd -g $gid builder && useradd -m -u $uid -g $gid builder
RUN mkdir -p /mnt/gradle-cache && chown -R builder:builder /mnt/gradle-cache

USER builder

ENV GRADLE_USER_HOME /mnt/gradle-cache
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH /usr/local/nodejs/bin:$JAVA_HOME/bin:$PATH

RUN mkdir -p /home/builder/.sbt /home/builder/.ivy2 /home/builder/.cache \
  && chown -R builder:builder /home/builder

VOLUME /home/builder/.sbt
VOLUME /home/builder/.ivy2
VOLUME /home/builder/.cache

WORKDIR /mnt
