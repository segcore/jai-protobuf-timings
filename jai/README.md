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

| Procedure                               | Create Object | Serialize           | Deserialize         | Cleanup | Total              | Bytes              |
| ---                                     | ---           | ---                 | ---                 | ---     | ---                | ---                |
| test_memcopy                            | 0.000         | 0.001 (5.803 Gb/s)  | 0.000 (27.935 Gb/s) | 0.000   | 0.007 (0.540 Gb/s) | 4194325 (4.0 Mb)   |
| test_memcopy (Arena)                    | 0.000         | 0.000 (43.809 Gb/s) | 0.000 (38.069 Gb/s) | 0.000   | 0.005 (0.850 Gb/s) | 4194325 (4.0 Mb)   |
| test_repeated_ints                      | 0.003         | 0.010 (0.343 Gb/s)  | 0.011 (0.331 Gb/s)  | 0.000   | 0.025 (0.144 Gb/s) | 3788658 (3.6 Mb)   |
| test_repeated_ints (Arena)              | 0.003         | 0.012 (0.289 Gb/s)  | 0.010 (0.360 Gb/s)  | 0.000   | 0.026 (0.135 Gb/s) | 3788658 (3.6 Mb)   |
| test_repeated_zigzag                    | 0.004         | 0.013 (0.275 Gb/s)  | 0.011 (0.341 Gb/s)  | 0.000   | 0.029 (0.127 Gb/s) | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Arena)            | 0.004         | 0.013 (0.288 Gb/s)  | 0.010 (0.374 Gb/s)  | 0.000   | 0.026 (0.138 Gb/s) | 3894341 (3.7 Mb)   |
| test_repeated_floats                    | 0.004         | 0.001 (5.641 Gb/s)  | 0.005 (0.759 Gb/s)  | 0.000   | 0.010 (0.382 Gb/s) | 4000021 (3.8 Mb)   |
| test_repeated_floats (Arena)            | 0.004         | 0.000 (15.765 Gb/s) | 0.004 (0.943 Gb/s)  | 0.000   | 0.008 (0.458 Gb/s) | 4000021 (3.8 Mb)   |
| test_repeated_strings                   | 0.123         | 0.024 (1.450 Gb/s)  | 0.027 (1.296 Gb/s)  | 0.004   | 0.178 (0.194 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Arena)           | 0.120         | 0.021 (1.622 Gb/s)  | 0.024 (1.425 Gb/s)  | 0.003   | 0.169 (0.204 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints                 | 0.044         | 0.054 (0.171 Gb/s)  | 0.082 (0.114 Gb/s)  | 0.000   | 0.181 (0.051 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Arena)         | 0.043         | 0.053 (0.174 Gb/s)  | 0.078 (0.119 Gb/s)  | 0.000   | 0.177 (0.052 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings         | 0.059         | 0.035 (1.390 Gb/s)  | 0.030 (1.631 Gb/s)  | 0.005   | 0.130 (0.376 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Arena) | 0.056         | 0.033 (1.480 Gb/s)  | 0.027 (1.793 Gb/s)  | 0.004   | 0.121 (0.404 Gb/s) | 52480857 (50.0 Mb) |
| test_submessages                        | 0.018         | 0.110 (0.297 Gb/s)  | 0.120 (0.271 Gb/s)  | 0.000   | 0.249 (0.131 Gb/s) | 35000026 (33.4 Mb) |
| test_submessages (Arena)                | 0.010         | 0.106 (0.307 Gb/s)  | 0.112 (0.292 Gb/s)  | 0.000   | 0.228 (0.143 Gb/s) | 35000026 (33.4 Mb) |

Disabling asserts produce a noticable improvement with floats, strings, maps
and submessages. Tested with:
```jai
#import "Basic"()(ENABLE_ASSERT=false);
```

| Procedure                               | Create Object | Serialize           | Deserialize         | Cleanup | Total              | Bytes              |
| ---                                     | ---           | ---                 | ---                 | ---     | ---                | ---                |
| test_memcopy                            | 0.000         | 0.001 (5.777 Gb/s)  | 0.000 (27.925 Gb/s) | 0.000   | 0.005 (0.809 Gb/s) | 4194325 (4.0 Mb)   |
| test_memcopy (Arena)                    | 0.000         | 0.000 (44.565 Gb/s) | 0.000 (37.758 Gb/s) | 0.000   | 0.003 (1.440 Gb/s) | 4194325 (4.0 Mb)   |
| test_repeated_ints                      | 0.001         | 0.011 (0.326 Gb/s)  | 0.006 (0.634 Gb/s)  | 0.000   | 0.018 (0.192 Gb/s) | 3788658 (3.6 Mb)   |
| test_repeated_ints (Arena)              | 0.001         | 0.011 (0.335 Gb/s)  | 0.005 (0.754 Gb/s)  | 0.000   | 0.016 (0.219 Gb/s) | 3788658 (3.6 Mb)   |
| test_repeated_zigzag                    | 0.001         | 0.012 (0.294 Gb/s)  | 0.006 (0.565 Gb/s)  | 0.000   | 0.020 (0.179 Gb/s) | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Arena)            | 0.001         | 0.014 (0.269 Gb/s)  | 0.005 (0.660 Gb/s)  | 0.000   | 0.020 (0.180 Gb/s) | 3894341 (3.7 Mb)   |
| test_repeated_floats                    | 0.001         | 0.001 (5.888 Gb/s)  | 0.002 (1.555 Gb/s)  | 0.000   | 0.005 (0.711 Gb/s) | 4000021 (3.8 Mb)   |
| test_repeated_floats (Arena)            | 0.001         | 0.000 (24.477 Gb/s) | 0.002 (1.783 Gb/s)  | 0.000   | 0.003 (1.135 Gb/s) | 4000021 (3.8 Mb)   |
| test_repeated_strings                   | 0.116         | 0.015 (2.272 Gb/s)  | 0.010 (3.575 Gb/s)  | 0.004   | 0.145 (0.236 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Arena)           | 0.113         | 0.013 (2.565 Gb/s)  | 0.007 (4.775 Gb/s)  | 0.003   | 0.138 (0.248 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints                 | 0.042         | 0.031 (0.298 Gb/s)  | 0.052 (0.178 Gb/s)  | 0.000   | 0.126 (0.074 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Arena)         | 0.039         | 0.033 (0.279 Gb/s)  | 0.049 (0.190 Gb/s)  | 0.000   | 0.121 (0.077 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings         | 0.058         | 0.028 (1.721 Gb/s)  | 0.023 (2.168 Gb/s)  | 0.005   | 0.114 (0.427 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Arena) | 0.055         | 0.026 (1.883 Gb/s)  | 0.020 (2.470 Gb/s)  | 0.004   | 0.105 (0.464 Gb/s) | 52480857 (50.0 Mb) |
| test_submessages                        | 0.014         | 0.065 (0.499 Gb/s)  | 0.049 (0.662 Gb/s)  | 0.001   | 0.130 (0.251 Gb/s) | 35000026 (33.4 Mb) |
| test_submessages (Arena)                | 0.008         | 0.065 (0.503 Gb/s)  | 0.042 (0.769 Gb/s)  | 0.000   | 0.116 (0.282 Gb/s) | 35000026 (33.4 Mb) |
