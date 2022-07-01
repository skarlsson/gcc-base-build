cmake_minimum_required(VERSION 2.8.11)
project(bb-monitor)

SET(CMAKE_CXX_STANDARD 17)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

option(BUILD_STATIC_LIBS "enable static linking support" ON)
option(BUILD_SHARED_LIBS "enable shared linking support" OFF)

#GLOBAL DEFINITIONS
add_definitions(-DRAPIDJSON_HAS_STDSTRING)
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -Wpedantic -Wreturn-type -O3")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wpedantic -Wreturn-type -g -O0")

set(BOOST_LIBS boost_program_options boost_iostreams boost_regex boost_system z bz2 pthread rt c)

SET(EXT_INCLUDE_PATH
        ${Boost_INCLUDE_DIR}
        ${RAPIDJSON_INCLUDE_DIR}
        )

SET(LIBRARY_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/lib)
SET(EXECUTABLE_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/bin)

add_definitions(-D_FILE_OFFSET_BITS=64 -D_REENTRANT -DEXTERNAL_LOCKS -DMULTITHREAD)
add_definitions(-fPIC)
add_definitions(-Wno-deprecated)
add_definitions(-g)

set(BOOST_LIBS boost_program_options boost_iostreams boost_filesystem boost_system boost_regex z bz2 pthread rt c)
SET(AWS_S3_LIBS aws-cpp-sdk-s3 aws-cpp-sdk-core aws-c-event-stream aws-checksums aws-c-common)
SET(ARROW_LIBS arrow arrow_dataset parquet)

SET(EXT_LIBS ${ARROW_LIBS} ${BOOST_LIBS} ${AWS_S3_LIBS} glog gflags crypto ssl stdc++fs dl)
#add local libs before EXT_LIBS
SET(ALL_LIBS ${EXT_LIBS} )

include_directories(${CMAKE_SOURCE_DIR})

add_subdirectory(examples)
