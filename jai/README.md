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

The best time is recorded for each section. All times are in *milliseconds*.

| Procedure                               | Create Object | Serialize        | Deserialize       | Cleanup | Total             | Bytes              |
| ---                                     | ---           | ---              | ---               | ---     | ---               | ---                |
| test_memcopy                            | 0.0           | 0.7 (5.88 Gb/s)  | 0.1 (43.42 Gb/s)  | 0.2     | 2.1 (1.86 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Arena)                    | 0.0           | 0.1 (47.20 Gb/s) | 0.1 (47.49 Gb/s)  | 0.0     | 0.4 (9.42 Gb/s)   | 4194325 (4.0 Mb)   |
| test_repeated_ints                      | 3.5           | 5.9 (0.60 Gb/s)  | 10.4 (0.34 Gb/s)  | 0.2     | 21.3 (0.17 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_ints (Arena)              | 3.2           | 5.4 (0.65 Gb/s)  | 9.4 (0.37 Gb/s)   | 0.0     | 19.1 (0.18 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_zigzag                    | 4.9           | 6.5 (0.56 Gb/s)  | 10.6 (0.34 Gb/s)  | 0.2     | 22.7 (0.16 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Arena)            | 3.9           | 6.6 (0.55 Gb/s)  | 9.7 (0.37 Gb/s)   | 0.0     | 20.5 (0.18 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_floats                    | 4.1           | 0.6 (5.76 Gb/s)  | 0.3 (11.37 Gb/s)  | 0.1     | 5.4 (0.69 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Arena)            | 2.9           | 0.1 (44.60 Gb/s) | 0.1 (36.72 Gb/s)  | 0.0     | 3.5 (1.06 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_strings                   | 121.3         | 18.8 (1.82 Gb/s) | 27.2 (1.26 Gb/s)  | 4.1     | 172.4 (0.20 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Arena)           | 118.4         | 16.0 (2.15 Gb/s) | 24.1 (1.42 Gb/s)  | 3.8     | 162.5 (0.21 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints                 | 46.5          | 39.0 (0.24 Gb/s) | 81.3 (0.11 Gb/s)  | 0.5     | 168.5 (0.06 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Arena)         | 40.1          | 38.1 (0.24 Gb/s) | 77.6 (0.12 Gb/s)  | 0.0     | 158.0 (0.06 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings         | 59.3          | 34.0 (1.44 Gb/s) | 29.9 (1.64 Gb/s)  | 5.5     | 128.9 (0.38 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Arena) | 55.8          | 31.9 (1.53 Gb/s) | 26.6 (1.84 Gb/s)  | 4.6     | 119.2 (0.41 Gb/s) | 52480857 (50.0 Mb) |
| test_submessages                        | 18.0          | 72.2 (0.45 Gb/s) | 119.5 (0.27 Gb/s) | 0.6     | 211.6 (0.15 Gb/s) | 35000026 (33.4 Mb) |
| test_submessages (Arena)                | 10.2          | 68.8 (0.47 Gb/s) | 110.5 (0.30 Gb/s) | 0.0     | 190.5 (0.17 Gb/s) | 35000026 (33.4 Mb) |

Disabling asserts produce a noticable improvement with strings, maps and
submessages. Tested with:
```jai
#import "Basic"()(ENABLE_ASSERT=false);
```

| Procedure                               | Create Object | Serialize        | Deserialize      | Cleanup | Total             | Bytes              |
| ---                                     | ---           | ---              | ---              | ---     | ---               | ---                |
| test_memcopy                            | 0.0           | 0.7 (5.86 Gb/s)  | 0.1 (43.23 Gb/s) | 0.2     | 2.1 (1.82 Gb/s)   | 4194325 (4.0 Mb)   |
| test_memcopy (Arena)                    | 0.0           | 0.1 (47.28 Gb/s) | 0.1 (47.39 Gb/s) | 0.0     | 0.4 (9.42 Gb/s)   | 4194325 (4.0 Mb)   |
| test_repeated_ints                      | 1.7           | 7.2 (0.49 Gb/s)  | 5.4 (0.66 Gb/s)  | 0.2     | 14.9 (0.24 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_ints (Arena)              | 0.9           | 7.9 (0.45 Gb/s)  | 4.6 (0.77 Gb/s)  | 0.0     | 13.3 (0.26 Gb/s)  | 3788658 (3.6 Mb)   |
| test_repeated_zigzag                    | 1.7           | 7.3 (0.50 Gb/s)  | 6.4 (0.57 Gb/s)  | 0.2     | 15.9 (0.23 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_zigzag (Arena)            | 0.9           | 7.7 (0.47 Gb/s)  | 5.5 (0.66 Gb/s)  | 0.0     | 14.2 (0.26 Gb/s)  | 3894341 (3.7 Mb)   |
| test_repeated_floats                    | 1.7           | 0.7 (5.73 Gb/s)  | 0.3 (10.71 Gb/s) | 0.1     | 2.8 (1.31 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_floats (Arena)            | 0.8           | 0.1 (40.66 Gb/s) | 0.1 (32.85 Gb/s) | 0.0     | 1.1 (3.53 Gb/s)   | 4000021 (3.8 Mb)   |
| test_repeated_strings                   | 118.4         | 11.3 (3.04 Gb/s) | 10.1 (3.41 Gb/s) | 4.1     | 144.8 (0.24 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_strings (Arena)           | 115.5         | 8.6 (4.01 Gb/s)  | 7.2 (4.78 Gb/s)  | 3.6     | 135.1 (0.25 Gb/s) | 36888913 (35.2 Mb) |
| test_repeated_maps_ints                 | 42.0          | 15.8 (0.59 Gb/s) | 51.5 (0.18 Gb/s) | 0.4     | 112.0 (0.08 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_ints (Arena)         | 37.1          | 14.3 (0.65 Gb/s) | 47.8 (0.19 Gb/s) | 0.0     | 101.3 (0.09 Gb/s) | 9966980 (9.5 Mb)   |
| test_repeated_maps_with_strings         | 58.9          | 21.2 (2.31 Gb/s) | 23.0 (2.13 Gb/s) | 5.2     | 108.6 (0.45 Gb/s) | 52480857 (50.0 Mb) |
| test_repeated_maps_with_strings (Arena) | 55.2          | 19.1 (2.56 Gb/s) | 19.8 (2.47 Gb/s) | 4.5     | 98.7 (0.50 Gb/s)  | 52480857 (50.0 Mb) |
| test_submessages                        | 14.6          | 36.6 (0.89 Gb/s) | 50.0 (0.65 Gb/s) | 0.5     | 102.2 (0.32 Gb/s) | 35000026 (33.4 Mb) |
| test_submessages (Arena)                | 8.3           | 33.7 (0.97 Gb/s) | 41.4 (0.79 Gb/s) | 0.0     | 83.7 (0.39 Gb/s)  | 35000026 (33.4 Mb) |
