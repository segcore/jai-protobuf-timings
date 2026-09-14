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

| Procedure                       | Create Object | Serialize           | Deserialize         | Cleanup | Total | Bytes                |
| ---                             | ---           | ---                 | ---                 | ---     | ---   | ---                  |
| test_repeated_ints              | 0.004         | 0.003 (1.261 Gb/s)  | 0.004 (0.805 Gb/s)  | 0.000   | 0.011 | 3788658 (3.6 Mb)     |
| test_repeated_zigzag            | 0.004         | 0.003 (1.174 Gb/s)  | 0.005 (0.767 Gb/s)  | 0.001   | 0.012 | 3894341 (3.7 Mb)     |
| test_repeated_floats            | 0.002         | 0.000 (43.724 Gb/s) | 0.000 (36.848 Gb/s) | 0.000   | 0.003 | 4000021 (3.8 Mb)     |
| test_repeated_strings           | 0.033         | 0.017 (1.975 Gb/s)  | 0.079 (0.434 Gb/s)  | 0.045   | 0.175 | 36888913 (35.2 Mb)   |
| test_repeated_maps_ints         | 0.124         | 0.075 (0.123 Gb/s)  | 0.041 (0.226 Gb/s)  | 0.174   | 0.414 | 9966980 (9.5 Mb)     |
| test_repeated_maps_with_strings | 0.489         | 0.493 (0.994 Gb/s)  | 0.275 (1.782 Gb/s)  | 0.688   | 1.945 | 526105858 (501.7 Mb) |
| test_submessages                | 0.034         | 0.027 (1.218 Gb/s)  | 0.076 (0.428 Gb/s)  | 0.061   | 0.197 | 35000026 (33.4 Mb)   |
