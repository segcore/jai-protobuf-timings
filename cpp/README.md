# C++ Protobuf Results

Compiled with the following commands.

```sh
# Debug
rm -rf build-debug
time (cmake . -B build-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug && cmake --build build-debug --parallel)

# Release
rm -rf build
time (cmake . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release     && cmake --build build --parallel)

# Incremental .cpp (release)
touch main.cpp
time cmake --build build

# Incremental .proto (release)
touch ../proto/sample.proto
time cmake --build build
```

## Compile times

Builds are performed with CMake and Ninja, and built in parallel.

First build must compile the protobuf libraries, protoc, etc., generate the C++ code, and
link it all together.

Incremental `main.cpp` means that main.cpp is touched before the incremental build.

Incremental `.proto` means that .proto file is touched before the incremental build.

All times are in seconds.

| Target  | First Build | Incremental main.cpp | Incremental .proto |
| ---     | ---         | ---                  | ---                |
| Debug   | 63.220      | 2.698                | 3.417              |
| Release | 108.758     | 2.393                | 3.657              |

## Run times (Release)

All times are in seconds.

| Procedure                       | Create Object | Serialize           | Deserialize         | Cleanup | Total              | Bytes              |
| ---                             | ---           | ---                 | ---                 | ---     | ---                | ---                |
| test_memcopy                    | 0.000         | 0.001 (5.261 Gb/s)  | 0.000 (40.699 Gb/s) | 0.000   | 0.003 (1.277 Gb/s) | 4194325 (4.0 Mb)   |
| test_repeated_ints              | 0.003         | 0.003 (1.263 Gb/s)  | 0.003 (1.069 Gb/s)  | 0.000   | 0.009 (0.386 Gb/s) | 3788658 (3.6 Mb)   |
| test_repeated_zigzag            | 0.004         | 0.003 (1.175 Gb/s)  | 0.004 (0.884 Gb/s)  | 0.000   | 0.011 (0.318 Gb/s) | 3894341 (3.7 Mb)   |
| test_repeated_floats            | 0.001         | 0.000 (44.224 Gb/s) | 0.000 (38.424 Gb/s) | 0.000   | 0.001 (2.892 Gb/s) | 4000021 (3.8 Mb)   |
| test_repeated_strings           | 0.037         | 0.017 (2.000 Gb/s)  | 0.078 (0.438 Gb/s)  | 0.044   | 0.179 (0.192 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints         | 0.133         | 0.076 (0.122 Gb/s)  | 0.041 (0.225 Gb/s)  | 0.172   | 0.430 (0.022 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings | 0.027         | 0.042 (1.157 Gb/s)  | 0.025 (1.940 Gb/s)  | 0.044   | 0.139 (0.351 Gb/s) | 52480857 (50.0 Mb) |
| test_submessages                | 0.034         | 0.029 (1.113 Gb/s)  | 0.116 (0.282 Gb/s)  | 0.056   | 0.237 (0.138 Gb/s) | 35000026 (33.4 Mb) |
