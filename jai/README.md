# Jai Protobuf Results

Compiled with

```sh
jai main.jai -x64 # Debug x64
jai main.jai      # Debug LLVM
jai main.jai -o   # Release
```

## Compile times

Jai does not do incremental builds. The protobuf parsing, code generation, and
compiliation all happens at build time. All time is included in the total time.

| Target     | Build Time (seconds) |
| ---        | ---                  |
| Debug x64  | 0.139                |
| Debug LLVM | 0.302                |
| Release    | 2.393                |

## Run times (Release)

All run times are in seconds.

| Procedure                       | Create Object | Serialize          | Deserialize        | Cleanup | Total | Bytes                |
| ---                             | ---           | ---                | ---                | ---     | ---   | ---                  |
| test_repeated_ints              | 0.004         | 0.016 (0.279 Gb/s) | 0.016 (0.272 Gb/s) | 0.000   | 0.037 | 4788653 (4.6 Mb)     |
| test_repeated_zigzag            | 0.004         | 0.016 (0.277 Gb/s) | 0.017 (0.267 Gb/s) | 0.000   | 0.038 | 4894336 (4.7 Mb)     |
| test_repeated_floats            | 0.003         | 0.006 (0.833 Gb/s) | 0.011 (0.435 Gb/s) | 0.000   | 0.020 | 5000016 (4.8 Mb)     |
| test_repeated_strings           | 0.126         | 0.025 (1.392 Gb/s) | 0.028 (1.228 Gb/s) | 0.004   | 0.183 | 36888913 (35.2 Mb)   |
| test_repeated_maps_ints         | 0.047         | 0.054 (0.172 Gb/s) | 0.085 (0.109 Gb/s) | 0.001   | 0.187 | 9966980 (9.5 Mb)     |
| test_repeated_maps_with_strings | 0.699         | 0.367 (1.336 Gb/s) | 0.288 (1.703 Gb/s) | 0.047   | 1.401 | 526105858 (501.7 Mb) |
| test_submessages                | 0.018         | 0.109 (0.299 Gb/s) | 0.121 (0.269 Gb/s) | 0.001   | 0.250 | 35000026 (33.4 Mb)   |
