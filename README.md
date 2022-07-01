#### basic dependencies set up for arrow/parquet dev with gcc10 on ubuntu 20.04
note - you need passwordless sudo for this to work

#### get rid of stuff you should not have
```
sudo apt-get --purge remove libprotobuf-dev libgrpc++-dev protobuf-compiler 
```

#### base dev tools
```
sudo apt-get install -y sudo build-essential cmake wget pax-utils automake autogen shtool libtool unzip pkg-config sed bison flex git 

#ubuntu 22 comes with gcc11 so this is bad
#sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 --slave /usr/bin/g++ g++ /usr/bin/g++-10 --slave /usr/bin/gcov gcov /usr/bin/gcov-10


```
#### common deps
```
sudo apt-get install -y libboost-all-dev libsnappy-dev google-mock libgtest-dev libgflags-dev
```
#### aws deps
```
#ubuntu 20
#sudo apt-get install -y libbz2-dev libssl-dev libcurl4-openssl-dev libgoogle-glog-dev

#ubuntu 22
sudo apt-get install -y libbz2-dev libssl-dev libcurl4-openssl-dev

```
#### deps for arrow
```
#20.04
#sudo apt-get install -y liblz4-dev libutf8proc-dev libre2-dev clang libz-dev liblzma-dev libzstd-dev libbz2-dev

#22
sudo apt-get install -y liblz4-dev libutf8proc-dev libre2-dev clang libz-dev liblzma-dev libzstd-dev libbz2-dev

#upgraded arrow ...
sudo apt-get install -y llvm-13 clang-13

```

#### deps for tf
```
sudo apt-get install -y libeigen3-dev
```

#### deps for kspp
```
sudo apt-get install -y libfmt-dev libpcre2-dev libhttp-parser-dev libpq-dev freetds-dev
```

### deps for scania
```
sudo apt-get install -y libleveldb-dev
```

#deps for seastar
sudo apt-get install -y libsctp-dev lksctp-tools libyaml-cpp-dev ragel xfslibs-dev valgrind systemtap-sdt-dev


sudo apt-get -y autoremove gnutls-dev

#### deps for pcap
```
sudo apt-get install -y libpcap-dev 
```


#### deps for anders & mdh-cpp
```
sudo apt-get install -y libhdf5-dev 
```


#### install packages from source
```
./3rdparty_install.sh
```


