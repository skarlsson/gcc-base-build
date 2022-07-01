FROM ubuntu:22.04

WORKDIR /root/tmp
MAINTAINER sk svante.karlsson@csi.se

ENV TZ=GMT
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

RUN apt-get update && apt-get install -y software-properties-common sudo build-essential cmake wget pax-utils automake autogen shtool libtool unzip pkg-config sed bison flex git curl apt-utils



#add repos and key servers for gcc and clang
RUN curl -sSL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
RUN apt-add-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-13 main"
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test

RUN apt-get update && apt-get install -y clang-13

RUN apt-get install -y libboost-all-dev libsnappy-dev libfmt-dev libpcre2-dev libhttp-parser-dev libpq-dev freetds-dev libgtest-dev libgflags-dev

#aws deps
RUN apt-get update &&  apt-get install -y  libssl-dev libcurl4-openssl-dev google-mock libgtest-dev libc-ares-dev 

#deps for arrow
#RUN  apt-get update && apt-get install -y llvm-7
RUN  apt-get update && apt-get install -y liblz4-dev libutf8proc-dev libre2-dev libz-dev liblzma-dev libzstd-dev libbz2-dev
RUN  apt-get update && apt-get install -y llvm-13 clang-13

#deps for tensorflow
RUN  apt-get update && apt-get install -y libeigen3-dev



#for KSPP
#RUN apt-get install -y libfmt-dev libpcre2-dev libhttp-parser-dev libpq-dev freetds-dev 

ENV CPP_STANDARD="17"
ENV AVRO_VER="release-1.11.0"
#ENV ABSEIL_CPP_VER="20200225.3"
ENV AWS_SDK_VER="1.9.242"
ENV GRPC_VER="v1.42.0"

#package not working on ubuntu 22.04 yet
ENV GLOG_VER="v0.6.0"

#deps for arrow
ENV DOUBLE_CONVERSION_VER="v3.1.5"
ENV BROTLI_VER="v1.0.9"
ENV FLATBUFFERS_VER="v1.11.0"
ENV THRIFT_VER="0.12.0"
ENV RAPIDJSON_VER="v1.1.0"

ENV ARROW_VER="apache-arrow-8.0.0"
ENV NLOHMANN_JSON_VER="v3.10.5"

#deps for kspp
ENV ROCKDB_VER="v7.2.0"
ENV LIBRDKAFKA_VER="v1.9.0-RC3"
ENV PROMETHEUS_CPP_VER="v1.0.0"
ENV HOWARD_HINNANT_VER="v3.0.0"
ENV CATCH2_VER="v2.13.2"
ENV RESTINIO_VER="v.0.6.10"



RUN wget -O avro.tar.gz "https://github.com/apache/avro/archive/$AVRO_VER.tar.gz" && \
mkdir -p avro && \
tar \
  --extract \
  --file avro.tar.gz \
  --directory avro \
  --strip-components 1 && \
sed -i.bak1 's/-std=c++11/-std=c++17/g' avro/lang/c++/CMakeLists.txt && \
cat avro/lang/c++/CMakeLists.txt && \
cd avro/lang/c++/  && \
mkdir build && \
cd build && \
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=$CPP_STANDARD .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../../../.. && \
rm avro.tar.gz && \
rm -rf avro

#RUN git clone --recursiv --depth 1 --branch master-with-bazel https://github.com/google/boringssl.git && \
#cd boringssl && \
#mkdir build && cd build && \
#cmake -DCMAKE_BUILD_TYPE=Release \
#  -DCMAKE_CXX_STANDARD=$CPP_STANDARD \
#  .. && \
#make -j "$(getconf _NPROCESSORS_ONLN)" && \
#sudo cp libcrypto.a /usr/local/lib/libboringssl-crypto.a && \
#sudo cp libssl.a /usr/local/lib/libboringssl-ssl.a && \
#cd ../.. && \
#rm -rf boringssl

#RUN wget -O abseil-cpp.tar.gz "https://github.com/abseil/abseil-cpp/archive/$ABSEIL_CPP_VER.tar.gz" && \
#mkdir -p abseil-cpp && \
#tar \
#  --extract \
# --file abseil-cpp.tar.gz \
#  --directory abseil-cpp \
#  --strip-components 1 && \
#cd abseil-cpp && \
#mkdir build && \
#cd build && \
#cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=$CPP_STANDARD .. && \
#make -j "$(getconf _NPROCESSORS_ONLN)" && \
#sudo make install && \
#cd ../.. && \
#rm abseil-cpp.tar.gz && \
#rm -rf abseil-cpp

RUN git clone --recursiv --depth 1 --branch $GRPC_VER https://github.com/grpc/grpc.git && \
cd grpc  && \
mkdir -p build && cd build  && \
cmake -DgRPC_SSL_PROVIDER=package ..  && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../.. && \
rm -rf grpc

RUN git clone --recurse-submodules --depth 1 --branch $AWS_SDK_VER https://github.com/aws/aws-sdk-cpp && \
cd aws-sdk-cpp && \
mkdir build-shared && cd build-shared && \
cmake -DCMAKE_BUILD_TYPE=Release  -D CMAKE_CXX_FLAGS="-Wno-error=deprecated-declarations" -DBUILD_SHARED_LIBS=ON -DBUILD_DEPS=ON DBUILD_ONLY="config;s3;transfer;sts;cognito-identity;identity-management" -DENABLE_TESTING=OFF -DCPP_STANDARD=$CPP_STANDARD .. && \
make -j 4 && \
#make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../.. && \
rm -rf aws-sdk-cpp

RUN wget -O double-conversion.tar.gz "https://github.com/google/double-conversion/archive/$DOUBLE_CONVERSION_VER.tar.gz" && \
mkdir -p double-conversion && \
tar \
  --extract \
  --file double-conversion.tar.gz \
  --directory double-conversion \
  --strip-components 1 && \
cd double-conversion && \
mkdir build && \
cd build && \
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=$CPP_STANDARD .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../.. && \
rm double-conversion.tar.gz && \
rm -rf double-conversion

RUN wget -O brotli.tar.gz "https://github.com/google/brotli/archive/$BROTLI_VER.tar.gz" && \
mkdir -p brotli && \
tar \
  --extract \
  --file brotli.tar.gz \
  --directory brotli \
  --strip-components 1 && \
cd brotli && \
mkdir build && \
cd build && \
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=$CPP_STANDARD .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../.. && \
rm brotli.tar.gz && \
rm -rf brotli


RUN wget -O flatbuffers.tar.gz "https://github.com/google/flatbuffers/archive/$FLATBUFFERS_VER.tar.gz" && \
mkdir -p flatbuffers && \
tar \
  --extract \
  --file flatbuffers.tar.gz \
  --directory flatbuffers \
  --strip-components 1 && \
cd flatbuffers && \
mkdir build && \
cd build && \
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DFLATBUFFERS_BUILD_TESTS=OFF -DCMAKE_CXX_STANDARD=$CPP_STANDARD .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../.. && \
rm flatbuffers.tar.gz && \
rm -rf flatbuffers

RUN wget -O thrift.tar.gz "https://github.com/apache/thrift/archive/$THRIFT_VER.tar.gz" && \
mkdir -p thrift && \
tar \
  --extract \
  --file thrift.tar.gz \
  --directory thrift \
  --strip-components 1 && \
cd thrift && \
mkdir -p build && cd build && \
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=$CPP_STANDARD .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../.. && \
rm thrift.tar.gz && \
rm -rf thrift


RUN wget -O nlomann.tar.gz "https://github.com/nlohmann/json/archive/$NLOHMANN_JSON_VER.tar.gz" && \
mkdir -p nlomann && \
tar \
  --extract \
  --file nlomann.tar.gz \
  --directory nlomann \
  --strip-components 1 && \
cd nlomann && \
mkdir build && cd build && \
cmake .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../.. && \
rm nlomann.tar.gz && \
rm -rf nlomann

#RUN wget -O rapidjson.tar.gz "https://github.com/miloyip/rapidjson/archive/$RAPIDJSON_VER.tar.gz" && \
#mkdir -p rapidjson && \
#tar \
#   --extract \
#   --file rapidjson.tar.gz \
#   --directory rapidjson \
#   --strip-components 1 && \
#cd rapidjson && \
##mkdir build && \
#cd build && \
#cmake -DRAPIDJSON_BUILD_EXAMPLES=OFF -DRAPIDJSON_BUILD_DOC=OFF -DRAPIDJSON_BUILD_TESTS=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=$CPP_STANDARD .. && \
#sudo make install && \
#sudo rm -rf /usr/local/share/doc/RapidJSON && \
#cd ../.. && \
#rm rapidjson.tar.gz && \
#rm -rf rapidjson

RUN  apt-get update && apt-get install -y rapidjson-dev 

#we now again have to build glog
RUN git clone --recursiv --depth 1 --branch $GLOG_VER https://github.com/google/glog.git && \
cd glog && \
mkdir build && cd build && \
cmake .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../.. && \
rm -rf glog



RUN wget -O arrow.tar.gz "https://github.com/apache/arrow/archive/$ARROW_VER.tar.gz" && \
mkdir -p arrow && \
tar \
  --extract \
  --file arrow.tar.gz \
  --directory arrow \
  --strip-components 1 && \
cd arrow/cpp && \
# https://github.com/apache/arrow/pull/8596/commits/39b6a98c4f460c3061c5b8c89c3b1eed9083b930
#sed -i.bak1 's/{GRPC_CPP_PLUGIN}/<TARGET_FILE:gRPC::grpc_cpp_plugin>/g' src/arrow/flight/CMakeLists.txt && \
mkdir build && \
cd build && \
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DARROW_DEPENDENCY_SOURCE=SYSTEM \
  -DCMAKE_CXX_STANDARD=$CPP_STANDARD \
  -DARROW_BUILD_UTILITIES=ON \
  -DARROW_CUDA=OFF \
  -DARROW_GANDIVA=OFF \
  -DARROW_WITH_BZ2=ON \
  -DARROW_WITH_ZLIB=ON \
  -DARROW_WITH_ZSTD=ON \
  -DARROW_WITH_LZ4=ON \
  -DARROW_WITH_SNAPPY=ON \
  -DARROW_WITH_BROTLI=ON \
  -DARROW_COMPUTE=ON \
  -DARROW_JEMALLOC=ON \
  -DARROW_CSV=ON \
  -DARROW_DATASET=ON \
  -DARROW_FILESYSTEM=ON \
  -DARROW_JSON=ON \
  -DARROW_PARQUET=ON \
  -DARROW_PLASMA=ON \
  -DARROW_PYTHON=OFF \
  -DARROW_FLIGHT=ON \
  -DARROW_S3=ON \
  -DARROW_USE_GLOG=ON \
  -DPARQUET_BUILD_EXECUTABLES=ON \
  -DPARQUET_BUILD_EXAMPLES=ON \
   .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../../.. && \
rm arrow.tar.gz && \
rm -rf arrow



RUN wget -O rocksdb.tar.gz "https://github.com/facebook/rocksdb/archive/$ROCKDB_VER.tar.gz" && \
mkdir -p rocksdb && \
tar \
    --extract \
    --file rocksdb.tar.gz \
    --directory rocksdb \
    --strip-components 1 && \
cd rocksdb && \
export USE_RTTI=1 && \
make -j "$(getconf _NPROCESSORS_ONLN)" shared_lib && \
sudo make install-shared && \
cd .. && \
rm rocksdb.tar.gz && \
rm -rf rocksdb

RUN wget -O prometheus-cpp.tar.gz "https://github.com/jupp0r/prometheus-cpp/archive/$PROMETHEUS_CPP_VER.tar.gz" && \
mkdir -p prometheus-cpp && \
tar \
  --extract \
  --file prometheus-cpp.tar.gz \
  --directory prometheus-cpp \
  --strip-components 1 && \
cd prometheus-cpp && \
mkdir build && cd build && \
cmake  -DCMAKE_BUILD_TYPE=Release -DENABLE_PULL=OFF -DUSE_THIRDPARTY_LIBRARIES=OFF -DENABLE_TESTING=OFF -DBUILD_SHARED_LIBS=ON -DOVERRIDE_CXX_STANDARD_FLAGS=OFF -DCMAKE_CXX_STANDARD=$CPP_STANDARD .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../.. && \
rm prometheus-cpp.tar.gz && \
rm -rf prometheus-cpp


RUN wget -O hh.tar.gz "https://github.com/HowardHinnant/date/archive/$HOWARD_HINNANT_VER.tar.gz" && \
mkdir -p hh && \
tar \
  --extract \
  --file hh.tar.gz \
  --directory hh \
  --strip-components 1 && \
cd hh && \
mkdir build && cd build && \
cmake -DUSE_SYSTEM_TZ_DB=ON -DBUILD_TZ_LIB=ON .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
make install && \
cd ../.. && \
rm hh.tar.gz && \
rm -rf hh

RUN wget -O catch2.tar.gz "https://github.com/catchorg/Catch2/archive/$CATCH2_VER.tar.gz" && \
mkdir -p catch2 && \
tar \
   --extract \
   --file catch2.tar.gz \
   --directory catch2 \
   --strip-components 1 && \
cd catch2 && \
mkdir build && cd build && \
cmake -DCATCH_BUILD_TESTING=OFF -DCATCH_INSTALL_DOCS=OFF .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
make install && \
cd ../.. && \
rm catch2.tar.gz && \
rm -rf catch2

RUN wget -O restinio.tar.gz "https://github.com/Stiffstream/restinio/archive/$RESTINIO_VER.tar.gz" && \
mkdir -p restinio && \
tar \
   --extract \
   --file restinio.tar.gz \
   --directory restinio \
   --strip-components 1 && \
cd restinio && \
cd dev && \
#sed -i.bak1 's/unofficial-http-parser/http-parser/g' CMakeLists.txt
sed -i.bak1 '/find_package(unofficial-http-parser/d' CMakeLists.txt && \
mkdir build && cd build && \
cmake -DRESTINIO_TEST=OFF -DRESTINIO_SAMPLE=OFF -DRESTINIO_INSTALL_SAMPLES=OFF -DRESTINIO_BENCH=OFF -DRESTINIO_INSTALL_BENCHES=OFF -DRESTINIO_FIND_DEPS=ON -DRESTINIO_ALLOW_SOBJECTIZER=OFF .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
make install && \
cd ../../.. && \
rm restinio.tar.gz && \
rm -rf restinio

RUN wget -O librdkafka.tar.gz "https://github.com/edenhill/librdkafka/archive/$LIBRDKAFKA_VER.tar.gz" && \
mkdir -p librdkafka && \
tar \
  --extract \
  --file librdkafka.tar.gz \
  --directory librdkafka \
  --strip-components 1 && \
cd librdkafka && \
./configure --prefix=/usr/local && \
#./configure --disable-ssl --prefix=/usr/local && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd .. && \
rm librdkafka.tar.gz && \
rm -rf librdkafka


#RUN wget -O pcapplusplus.tar.gz "https://github.com/seladb/PcapPlusPlus/archive/v20.08.tar.gz" && \
#mkdir -p pcapplusplus && \
#tar \
#  --extract \
#  --file pcapplusplus.tar.gz \
#  --directory pcapplusplus \
#  --strip-components 1 && \
#cd pcapplusplus && \
#./configure-linux.sh --default && \
#make -j "$(getconf _NPROCESSORS_ONLN)" && \
#sudo make install && \
#sudo rm  /usr/local/bin/Pcap* && \
#sudo rm  /usr/local/bin/Arp* && \
#sudo rm  /usr/local/bin/DNSResolver && \
#sudo rm  /usr/local/bin/DnsSpoofing && \
#sudo rm  /usr/local/bin/Icmp* && \
#sudo rm  /usr/local/bin/IPDefragUtil* && \
#sudo rm  /usr/local/bin/IPFragUtil* && \
#cd .. && \
#rm pcapplusplus.tar.gz && \
#rm -rf pcapplusplus

RUN wget -O api-common-protos.tar.gz "https://github.com/googleapis/api-common-protos/archive/1.50.0.tar.gz" && \
mkdir -p api-common-protos && \
tar \
  --extract \
  --file api-common-protos.tar.gz \
  --directory api-common-protos \
  --strip-components 1 && \
cd api-common-protos && \
sudo cp -r google/* /usr/local/include/google/ && \
cd .. && \
rm api-common-protos.tar.gz && \
rm -rf api-common-protos

RUN wget -O quantlib.tar.gz "https://github.com/lballabio/QuantLib/archive/QuantLib-v1.24.tar.gz" && \
mkdir -p quantlib && \
tar \
  --extract \
  --file quantlib.tar.gz \
  --directory quantlib \
  --strip-components 1 && \
cd quantlib && \
./autogen.sh && \
./configure --enable-std-classes && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
sudo rm  /usr/local/bin/quantlib* && \
cd .. && \
rm quantlib.tar.gz && \
rm -rf quantlib

#COPY cmake cmake
#COPY examples examples
#COPY CMakeLists.txt  .

#RUN mkdir build && \
#    cd build && \
#    cmake  -DCMAKE_BUILD_TYPE=Release .. && \
#    make -j "$(getconf _NPROCESSORS_ONLN)" && \
#    make install && \
#    strip --strip-all /usr/local/lib/*.so* && \
#    strip --strip-unneeded /usr/local/bin/* && \
#    cd .. && \
#    rm -rf build

RUN runDeps="$( \
      scanelf --needed --nobanner --recursive /usr/local \
        | awk '{ gsub(/,/, "\n", $2); print $2 }' \
        | sort -u \
        | xargs -r dpkg -S | cut -d : -f 1  \
        | sort -u \
      )" && \
     echo "$runDeps" > runDeps


