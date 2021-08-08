FROM debian:9-slim
# FROM debian:9
# Debian dependencies
COPY CsMapDev-14.01.zip .
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list; \
    apt-get update && apt-get upgrade -y && apt-get --no-install-recommends -y install \
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
    zip \
    unzip; \
    # Accelerated github source, especially in China
    git config --global url."https://github.com.cnpmjs.org/".insteadOf "https://github.com/";\
    # request
    pip install requests -i https://pypi.tuna.tsinghua.edu.cn/simple ;\
    #  Node
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && apt-get update && apt-get install -y nodejs; \
    #Geospatial
    curl -sL http://download.osgeo.org/libspatialindex/spatialindex-src-1.8.5.tar.gz | tar xvz; \ 
    cd spatialindex-src-1.8.5 && ./configure && make && make install; \
    curl -sL http://download.osgeo.org/geos/geos-3.5.1.tar.bz2 | tar vxj; \
    cd geos-3.5.1 && ./configure && make && make install; \
    #Erlang
    wget https://packages.erlang-solutions.com/erlang/debian/pool/esl-erlang_22.3.4.9-1~debian~stretch_amd64.deb; \
    dpkg --force-depends -i esl-erlang_22.3.4.9-1~debian~stretch_amd64.deb; \
    apt-get --fix-broken install -y;\
    # CsMap, CouchDB
    # Please use the following link to download, anti-comment the line of _COPY,
    # because the file size limit, I did not upload the file up
    # cd / && wget -O CsMapDev-14.01.zip https://trac.osgeo.org/csmap/browser/branches/14.01/CsMapDev?rev=2854&format=zip;\
    cd / && unzip CsMapDev-14.01.zip && cd /CsMapDev/Source && make -fLibrary.mak; \
    cd /CsMapDev/Dictionaries && make -fCompiler.mak && ./CS_Comp . . ; \
    cd /CsMapDev/Test && make -fTest.mak && ./CS_Test -d../Dictionaries ; \
    mkdir -p /usr/share/CsMap/dict; \
    cp -r /CsMapDev/Include /usr/local/include/CsMap && cp /CsMapDev/Source/CsMap.a /usr/local/lib/libCsMap.a && cp -r /CsMapDev/Dictionaries/* /usr/share/CsMap/dict && ldconfig;\
    cd / && git clone https://github.com/apache/couchdb
WORKDIR /couchdb
RUN git checkout 3.1.1
COPY hastings-fixer.sh .
RUN ./hastings-fixer.sh before-configure;\
    ./configure --disable-docs; \
    ./hastings-fixer.sh; \
    make release;\
    # Docker config adjustments
    sed -e 's/^bind_address = .*$/bind_address = 0.0.0.0/' -i rel/couchdb/etc/default.ini;\
    sed -e 's!/usr/local/var/log/couchdb/couch.log$!/dev/null!' -i rel/couchdb/etc/default.ini;\
    echo "admin = adminpw" >> rel/couchdb/etc/local.ini
COPY sample rel/sample/
WORKDIR /
RUN cp -r /couchdb/rel rel && rm -rf CsMapDev  CsMapDev-14.01.zip couchdb spatialindex-src-1.8.5 /tmp/* /var/lib/apt/lists/*;\
    apt-get remove --purge -y nodejs zip unzip vim vim-gui-common build-essential git wget gcc g++ make ssh pkg-config libcurl4-openssl-dev && apt-get autoclean -y && apt-get clean -y && apt-get autoremove -y
CMD rel/couchdb/bin/couchdb
EXPOSE 5984
