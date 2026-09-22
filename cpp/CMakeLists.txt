cmake_minimum_required(VERSION 3.0...5.0)

project(cpp_protobuf_timings)

add_executable(cpp main.cpp)

add_subdirectory(protobuf)

add_library(proto_cpp OBJECT)
include(FindProtobuf)
protobuf_generate(
    TARGET proto_cpp
    LANGUAGE cpp
    PROTOC_OUT_DIR generated
    PROTOS ../proto/sample.proto ../proto/test_results.proto
    IMPORT_DIRS ../proto
)
target_link_libraries(proto_cpp PUBLIC libprotobuf)
target_include_directories(proto_cpp PUBLIC "${CMAKE_CURRENT_BINARY_DIR}/generated")
target_link_libraries(cpp PUBLIC proto_cpp)
