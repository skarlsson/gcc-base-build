set -ef

export CPP_STANDARD="17"

export AVRO_VER="release-1.11.0"
#export ABSEIL_CPP_VER="20200225.3"
#export ABSEIL_CPP_VER="20210324.2"
export AWS_SDK_VER="1.9.242"
export GRPC_VER="v1.42.0"

#deps for arrow
export DOUBLE_CONVERSION_VER="v3.1.5"
export BROTLI_VER="v1.0.9"
export FLATBUFFERS_VER="v1.11.0"
export THRIFT_VER="0.12.0"
#export RAPIDJSON_VER="v1.1.0"



export ARROW_VER="apache-arrow-8.0.0"

export NLOHMANN_JSON_VER="v3.10.5"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

rm -rf tmp
mkdir tmp
cd tmp


#suddenly glog from packet seems broken on arrow 8 as well - so lets build that always....
sudo apt-get purge libgoogle-glog-dev
sudo apt-get install libgflags-dev

#package not working on ubuntu 22.04 yet
#if package is installed - skip source build
if [ $(dpkg-query -W -f='${Status}' libgoogle-glog-dev 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  export GLOG_VER="v0.6.0"
  echo "glog found skipping source build."
  git clone --recursiv --depth 1 --branch $GLOG_VER https://github.com/google/glog.git && \
  cd glog && \
  mkdir build && cd build && \
  cmake .. && \
  make -j "$(getconf _NPROCESSORS_ONLN)" && \
  sudo make install && \
  cd ../..
fi


wget -O avro.tar.gz "https://github.com/apache/avro/archive/$AVRO_VER.tar.gz"
mkdir -p avro
tar \
  --extract \
  --file avro.tar.gz \
  --directory avro \
  --strip-components 1
sed -i.bak1 's/-std=c++11/-std=c++17/g' avro/lang/c++/CMakeLists.txt
cat avro/lang/c++/CMakeLists.txt
cd avro/lang/c++/
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=$CPP_STANDARD ..
make -j "$(getconf _NPROCESSORS_ONLN)"
sudo make install
cd ../../../..


git clone --recursiv --depth 1 --branch $GRPC_VER https://github.com/grpc/grpc.git && \
cd grpc && \
rm -r third_party/boringssl-with-bazel && \
mkdir build && cd build && \
cmake -DgRPC_SSL_PROVIDER=package .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../..

git clone --recurse-submodules --depth 1 --branch $AWS_SDK_VER https://github.com/aws/aws-sdk-cpp && \
cd aws-sdk-cpp && \
mkdir build-shared && cd build-shared && \
cmake -DCMAKE_BUILD_TYPE=Release  -D CMAKE_CXX_FLAGS="-Wno-error=deprecated-declarations" -DBUILD_SHARED_LIBS=ON -DBUILD_DEPS=ON DBUILD_ONLY="config;s3;transfer;sts;cognito-identity;identity-management" -DENABLE_TESTING=OFF -DCPP_STANDARD=$CPP_STANDARD .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../..


wget -O double-conversion.tar.gz "https://github.com/google/double-conversion/archive/$DOUBLE_CONVERSION_VER.tar.gz" && \
mkdir -p double-conversion && \
tar \
  --extract \
  --file double-conversion.tar.gz \
  --directory double-conversion \
  --strip-components 1
cd double-conversion
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=$CPP_STANDARD ..
make -j "$(getconf _NPROCESSORS_ONLN)"
sudo make install
cd ../..

wget -O brotli.tar.gz "https://github.com/google/brotli/archive/$BROTLI_VER.tar.gz" && \
mkdir -p brotli && \
tar \
  --extract \
  --file brotli.tar.gz \
  --directory brotli \
  --strip-components 1
cd brotli
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=$CPP_STANDARD ..
make -j "$(getconf _NPROCESSORS_ONLN)"
sudo make install
cd ../..


wget -O flatbuffers.tar.gz "https://github.com/google/flatbuffers/archive/$FLATBUFFERS_VER.tar.gz" && \
mkdir -p flatbuffers && \
tar \
  --extract \
  --file flatbuffers.tar.gz \
  --directory flatbuffers \
  --strip-components 1
cd flatbuffers
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DFLATBUFFERS_BUILD_TESTS=OFF -DCMAKE_CXX_STANDARD=$CPP_STANDARD ..
make -j "$(getconf _NPROCESSORS_ONLN)"
sudo make install
cd ../..

wget -O thrift.tar.gz "https://github.com/apache/thrift/archive/$THRIFT_VER.tar.gz" && \
mkdir -p thrift && \
tar \
  --extract \
  --file thrift.tar.gz \
  --directory thrift \
  --strip-components 1 && \
cd thrift && \
mkdir -p build && cd build && \
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=$CPP_STANDARD -DBUILD_JAVA=OFF -DBUILD_PYTHON=OFF -DBUILD_TESTING=OFF -DBUILD_TUTORIALS=OFF .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../..

wget -O nlomann.tar.gz "https://github.com/nlohmann/json/archive/$NLOHMANN_JSON_VER.tar.gz" && \
mkdir -p nlomann && \
tar \
  --extract \
  --file nlomann.tar.gz \
  --directory nlomann \
  --strip-components 1 && \
cd nlomann && \
mkdir build && cd build
cmake ..
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../..

#wget -O rapidjson.tar.gz "https://github.com/miloyip/rapidjson/archive/$RAPIDJSON_VER.tar.gz" && \
#mkdir -p rapidjson && \
#tar \
#   --extract \
#   --file rapidjson.tar.gz \
#   --directory rapidjson \
#   --strip-components 1 && \
#mkdir build && \
#cd build && \
#cmake -DRAPIDJSON_BUILD_EXAMPLES=OFF -DRAPIDJSON_BUILD_DOC=OFF -DRAPIDJSON_BUILD_TESTS=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=$CPP_STANDARD .. && \
#make -j "$(getconf _NPROCESSORS_ONLN)" && \
#sudo make install && \
#sudo rm -rf /usr/local/share/doc/RapidJSON && \
#cd ../..


wget -O arrow.tar.gz "https://github.com/apache/arrow/archive/$ARROW_VER.tar.gz" && \
mkdir -p arrow && \
tar \
  --extract \
  --file arrow.tar.gz \
  --directory arrow \
  --strip-components 1 && \
cd arrow/cpp && \
#sed -i.bak1 's/{GRPC_CPP_PLUGIN}/<TARGET_FILE:gRPC::grpc_cpp_plugin>/g' src/arrow/flight/CMakeLists.txt && \
mkdir build && \
cd build && \
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DARROW_DEPENDENCY_SOURCE=SYSTEM \
  -DCMAKE_CXX_STANDARD=$CPP_STANDARD \
  -DARROW_BUILD_UTILITIES=ON \
  -DARROW_CUDA=OFF \
  -DARROW_GANDIVA=ON \
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
cd ../../..



export ROCKDB_VER="v7.2.0"
export LIBRDKAFKA_VER="v1.9.0-RC3"
export PROMETHEUS_CPP_VER="v1.0.0"
export HOWARD_HINNANT_VER="v3.0.0"
export CATCH2_VER="v2.13.2"
export RESTINIO_VER="v.0.6.10"


wget -O rocksdb.tar.gz "https://github.com/facebook/rocksdb/archive/$ROCKDB_VER.tar.gz" && \
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
cd ..

wget -O prometheus-cpp.tar.gz "https://github.com/jupp0r/prometheus-cpp/archive/$PROMETHEUS_CPP_VER.tar.gz" && \
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

wget -O hh.tar.gz "https://github.com/HowardHinnant/date/archive/$HOWARD_HINNANT_VER.tar.gz" && \
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
sudo make install && \
cd ../.. && \
rm hh.tar.gz && \
rm -rf hh

wget -O catch2.tar.gz "https://github.com/catchorg/Catch2/archive/$CATCH2_VER.tar.gz" && \
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
sudo make install && \
cd ../.. && \
rm catch2.tar.gz && \
rm -rf catch2

wget -O restinio.tar.gz "https://github.com/Stiffstream/restinio/archive/$RESTINIO_VER.tar.gz" && \
mkdir -p restinio && \
tar \
   --extract \
   --file restinio.tar.gz \
   --directory restinio \
   --strip-components 1 && \
cd restinio && \
cd dev && \
sed -i.bak1 '/find_package(unofficial-http-parser/d' CMakeLists.txt && \
mkdir build && cd build && \
cmake -DRESTINIO_TEST=OFF -DRESTINIO_SAMPLE=OFF -DRESTINIO_INSTALL_SAMPLES=OFF -DRESTINIO_BENCH=OFF -DRESTINIO_INSTALL_BENCHES=OFF -DRESTINIO_FIND_DEPS=ON -DRESTINIO_ALLOW_SOBJECTIZER=OFF .. && \
make -j "$(getconf _NPROCESSORS_ONLN)" && \
sudo make install && \
cd ../../.. && \
rm restinio.tar.gz && \
rm -rf restinio

wget -O librdkafka.tar.gz "https://github.com/edenhill/librdkafka/archive/$LIBRDKAFKA_VER.tar.gz" && \
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
cd ..


#wget -O pcapplusplus.tar.gz "https://github.com/seladb/PcapPlusPlus/archive/v20.08.tar.gz" && \
#mkdir -p pcapplusplus && \
#tar \
#  --extract \
#  --file pcapplusplus.tar.gz \
#  --directory pcapplusplus \
#  --strip-components 1 && \
#d pcapplusplus && \
#./configure-linux.sh --default && \
#make -j "$(getconf _NPROCESSORS_ONLN)" && \
#sudo make install && \
#cd .. && \
#rm pcapplusplus.tar.gz && \
#rm -rf pcapplusplus

wget -O api-common-protos.tar.gz "https://github.com/googleapis/api-common-protos/archive/1.50.0.tar.gz" && \
mkdir -p api-common-protos && \
tar \
  --extract \
  --file api-common-protos.tar.gz \
  --directory api-common-protos \
  --strip-components 1 && \
cd api-common-protos
sudo cp -r google /usr/local/include
cd ..
rm api-common-protos.tar.gz
rm -rf api-common-protos

wget -O quantlib.tar.gz "https://github.com/lballabio/QuantLib/archive/QuantLib-v1.24.tar.gz" && \
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
cd .. && \
rm quantlib.tar.gz && \
rm -rf quantlib


#out of tmp
cd ..
rm -rf tmp



