# Jai Protobuf Results

Compiled with

```sh
time jai main.jai -x64 # Debug x64
time jai main.jai      # Debug LLVM
time jai main.jai -o   # Release
```

## Compile times

Jai does not do incremental builds. The protobuf parsing, code generation, and
compiliation all happens at build time. All time is included in the total time.

| Target     | Build Time (seconds) |
| ---        | ---                  |
| Debug x64  | 0.170                |
| Debug LLVM | 0.316                |
| Release    | 2.496                |

## Run times (Release)

All run times are in seconds.

| Procedure                       | Create Object | Serialize          | Deserialize        | Cleanup | Total | Bytes                |
| ---                             | ---           | ---                | ---                | ---     | ---   | ---                  |
| test_repeated_ints              | 0.004         | 0.009 (0.386 Gb/s) | 0.010 (0.345 Gb/s) | 0.000   | 0.023 | 3788658 (3.6 Mb)     |
| test_repeated_zigzag            | 0.005         | 0.011 (0.326 Gb/s) | 0.011 (0.342 Gb/s) | 0.000   | 0.027 | 3894341 (3.7 Mb)     |
| test_repeated_floats            | 0.004         | 0.001 (6.116 Gb/s) | 0.005 (0.768 Gb/s) | 0.000   | 0.009 | 4000021 (3.8 Mb)     |
| test_repeated_strings           | 0.127         | 0.024 (1.438 Gb/s) | 0.027 (1.264 Gb/s) | 0.004   | 0.182 | 36888913 (35.2 Mb)   |
| test_repeated_maps_ints         | 0.047         | 0.054 (0.172 Gb/s) | 0.081 (0.114 Gb/s) | 0.000   | 0.182 | 9966980 (9.5 Mb)     |
| test_repeated_maps_with_strings | 0.688         | 0.357 (1.374 Gb/s) | 0.287 (1.705 Gb/s) | 0.047   | 1.379 | 526105858 (501.7 Mb) |
| test_submessages                | 0.017         | 0.108 (0.300 Gb/s) | 0.120 (0.271 Gb/s) | 0.001   | 0.247 | 35000026 (33.4 Mb)   |
