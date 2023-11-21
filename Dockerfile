
FROM arm64v8/debian:10-slim
# NOTE: Both 10 and 10-slim works. Using 10-slim to cut down image.

# Install OS dependencies + scrub cache

RUN set -eux; apt-get update; apt-get install -y --no-install-recommends ca-certificates curl netbase wget ; rm -rf /var/lib/apt/lists/*
RUN set -ex; if ! command -v gpg > /dev/null; then apt-get update; apt-get install -y --no-install-recommends gnupg dirmngr ; rm -rf /var/lib/apt/lists/*; fi

# Install software dependencies + scrub cache

RUN apt-get update  \
	&& apt-get install -y --no-install-recommends git mercurial openssh-client subversion procps  \
	&& rm -rf /var/lib/apt/lists/*

# Install code build tools + scrub cache

RUN set -ex; apt-get update; apt-get install -y --no-install-recommends autoconf automake bzip2 dpkg-dev file g++ gcc imagemagick libbz2-dev libc6-dev libcurl4-openssl-dev libdb-dev libevent-dev libffi-dev libgdbm-dev libglib2.0-dev libgmp-dev libjpeg-dev libkrb5-dev liblzma-dev libmagickcore-dev libmagickwand-dev libmaxminddb-dev libncurses5-dev libncursesw5-dev libpng-dev libpq-dev libreadline-dev libsqlite3-dev libssl-dev libtool libwebp-dev libxml2-dev libxslt-dev libyaml-dev make patch unzip xz-utils zlib1g-dev $( if apt-cache show 'default-libmysqlclient-dev' 2>/dev/null | grep -q '^Version:'; then echo 'default-libmysqlclient-dev'; else echo 'libmysqlclient-dev'; fi ) ; rm -rf /var/lib/apt/lists/*
RUN set -eux; mkdir -p /usr/local/etc; { echo 'install: --no-document'; echo 'update: --no-document'; } >> /usr/local/etc/gemrc

# Apply environment variables for ruby build (+ pin vesions)

ENV LANG=C.UTF-8
ENV RUBY_MAJOR=2.7
ENV RUBY_VERSION=2.7.7
ENV RUBY_DOWNLOAD_SHA256=b38dff2e1f8ce6e5b7d433f8758752987a6b2adfd9bc7571dbc42ea5d04e3e4c

# Download and run ruby build

RUN set -eux; savedAptMark="$(apt-mark showmanual)"; apt-get update; apt-get install -y --no-install-recommends bison dpkg-dev libgdbm-dev ruby ; rm -rf /var/lib/apt/lists/*; wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz"; echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum --check --strict; mkdir -p /usr/src/ruby; tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1; rm ruby.tar.xz; cd /usr/src/ruby; { echo '#define ENABLE_PATH_CHECK 0'; echo; cat file.c; } > file.c.new; mv file.c.new file.c; autoconf; gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; ./configure --build="$gnuArch" --disable-install-doc --enable-shared ; make -j "$(nproc)"; make install; apt-mark auto '.*' > /dev/null; apt-mark manual $savedAptMark > /dev/null; find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' | awk '/=>/ { print $(NF-1) }' | sort -u | xargs -r dpkg-query --search | cut -d: -f1 | sort -u | xargs -r apt-mark manual ; apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; cd /; rm -r /usr/src/ruby; ! dpkg -l | grep -i ruby; [ "$(command -v ruby)" = '/usr/local/bin/ruby' ]; ruby --version; gem --version; bundle --version

# Set environment variables for gem installs (+ pin versions)

ENV GEM_HOME=/usr/local/bundle
ENV BUNDLE_SILENCE_ROOT_WARNING=1 BUNDLE_APP_CONFIG=/usr/local/bundle
ENV PATH=/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV GITHUB_PAGES_V=228

# Make gem directory

RUN mkdir -p "$GEM_HOME"  \
	&& chmod 777 "$GEM_HOME"

# Launch interactive ruby

CMD ["irb"]

# Update Apt database + install build tools + software packages

RUN apt-get update  \
	&& apt-get install -y build-essential  \
	&& apt-get install -y zlib1g-dev  \
	&& gem install github-pages -v $GITHUB_PAGES_V  \
	&& mkdir /var/jekyll # buildkit

# Expose port TCP/400 and change working directory

EXPOSE 4000/tcp
WORKDIR /var/jekyll