FROM debian:9
# Debian dependencies
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
RUN apt-get update && apt-get upgrade -y && apt-get --no-install-recommends -y install \
build-essential \
ca-certificates \
curl \
git \
libicu-dev \
libmozjs185-dev \
libcurl4-openssl-dev \
lsb-release \
pkg-config \
python-pip \
ssh \
vim \
vim-gui-common \
wget \
gnupg2 \
libleveldb-dev \
zip

# Accelerated github source, especially in China
RUN git config --global url."https://github.com.cnpmjs.org/".insteadOf "https://github.com/"

# request
RUN pip install requests -i https://pypi.tuna.tsinghua.edu.cn/simple

# Node
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get update
RUN apt-get install -y nodejs

# Geospatial
RUN curl -sL http://download.osgeo.org/libspatialindex/spatialindex-src-1.8.5.tar.gz | tar xvz
RUN cd spatialindex-src-1.8.5 && ./configure && make && make install
RUN curl -sL http://download.osgeo.org/geos/geos-3.5.1.tar.bz2 | tar vxj
RUN cd geos-3.5.1 && ./configure && make && make install

# Erlang
RUN wget https://packages.erlang-solutions.com/erlang/debian/pool/esl-erlang_22.3.4.9-1~debian~stretch_amd64.deb
RUN dpkg --force-depends -i esl-erlang_22.3.4.9-1~debian~stretch_amd64.deb
RUN apt --fix-broken install -y

# CsMap
# Please use the following link to download, anti-comment the line of _COPY,
# because the file size limit, I did not upload the file up
# wget https://trac.osgeo.org/csmap/browser/branches/14.01/CsMapDev?rev=2854&format=zip -O CsMapDev-14.01.zip
COPY CsMapDev-14.01.zip .
RUN apt-get install unzip
RUN unzip CsMapDev-14.01.zip
RUN cd CsMapDev/Source && make -fLibrary.mak
RUN cd CsMapDev/Dictionaries && make -fCompiler.mak && ./CS_Comp . .
RUN cd CsMapDev/Test && make -fTest.mak && ./CS_Test -d../Dictionaries
RUN mkdir -p /usr/share/CsMap/dict
RUN cp -r CsMapDev/Include /usr/local/include/CsMap && cp CsMapDev/Source/CsMap.a /usr/local/lib/libCsMap.a && cp -r CsMapDev/Dictionaries/* /usr/share/CsMap/dict && ldconfig

# CouchDB
RUN git clone https://github.com/apache/couchdb
WORKDIR /couchdb
RUN git checkout 3.1.1
COPY hastings-fixer.sh .
RUN ./hastings-fixer.sh before-configure
# RUN ./configure --disable-docs  --disable-fauxton
RUN ./configure --disable-docs
RUN ./hastings-fixer.sh
RUN make release

# Single Node setup
# COPY data rel/couchdb/data

# Docker config adjustments
RUN sed -e 's/^bind_address = .*$/bind_address = 0.0.0.0/' -i rel/couchdb/etc/default.ini
RUN sed -e 's!/usr/local/var/log/couchdb/couch.log$!/dev/null!' -i rel/couchdb/etc/default.ini
RUN echo "admin = adminpw" >> rel/couchdb/etc/local.ini

# Prepare sample tests
COPY loader_ski_areas.py /couchdb/src/hastings/sample
COPY loader.py /couchdb/src/hastings/sample
# RUN ls *.py | xargs sed -i 's/15984/5984/'

WORKDIR /couchdb
# RUN adduser --system \
#         --shell /bin/bash \
#         --group --gecos \
#         "CouchDB Administrator" couchdb

# RUN chown -R couchdb:couchdb rel/couchdb
# RUN find rel/couchdb -type d -exec chmod 0770 {} \;
# RUN chmod 0644 rel/couchdb/etc/*

# Start server
CMD rel/couchdb/bin/couchdb
EXPOSE 5984
