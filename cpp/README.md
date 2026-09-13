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

| Procedure                       | Create Object | Serialize           | Deserialize        | Cleanup | Total | Bytes                |
| ---                             | ---           | ---                 | ---                | ---     | ---   | ---                  |
| test_repeated_ints              | 0.004         | 0.003 (1.044 Gb/s)  | 0.004 (0.797 Gb/s) | 0.000   | 0.012 | 3788658 (3.6 Mb)     |
| test_repeated_zigzag            | 0.004         | 0.003 (1.109 Gb/s)  | 0.004 (0.811 Gb/s) | 0.001   | 0.012 | 3894341 (3.7 Mb)     |
| test_repeated_floats            | 0.003         | 0.000 (36.855 Gb/s) | 0.001 (5.538 Gb/s) | 0.000   | 0.003 | 4000021 (3.8 Mb)     |
| test_repeated_strings           | 0.065         | 0.017 (1.976 Gb/s)  | 0.076 (0.452 Gb/s) | 0.048   | 0.206 | 36888913 (35.2 Mb)   |
| test_repeated_maps_ints         | 0.131         | 0.076 (0.122 Gb/s)  | 0.042 (0.221 Gb/s) | 0.175   | 0.425 | 9966980 (9.5 Mb)     |
| test_repeated_maps_with_strings | 0.643         | 0.504 (0.973 Gb/s)  | 0.468 (1.047 Gb/s) | 0.698   | 2.312 | 526105858 (501.7 Mb) |
| test_submessages                | 0.035         | 0.027 (1.210 Gb/s)  | 0.073 (0.444 Gb/s) | 0.050   | 0.186 | 35000026 (33.4 Mb)   |
