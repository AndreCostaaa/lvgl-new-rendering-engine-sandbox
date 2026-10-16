# LVGL Rendering Engine Sandbox

A workspace for compile-checking LVGL's multiple draw units against an LVGL branch.

Under the hood it uses Zephyr for MCU based draw units. The other draw units can be tested on Linux even though some may require a separate SDK.

## Setup

Install the [Zephyr SDK](https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html), CMake, Ninja,
and the SDL2, EGL, GLESv2 and GLFW3 development headers. Then:

```sh
mkdir lvgl-sandbox && cd lvgl-sandbox
python3 -m venv .venv && source .venv/bin/activate
pip install west
west init -m https://github.com/AndreCostaaa/lvgl-new-rendering-engine-sandbox
west update --narrow -o=--depth=1
pip install -r zephyr/scripts/requirements.txt "esptool>=5.0.2"
```

## Build and test

Select the LVGL branch to test:

```sh
sandbox/scripts/use-lvgl.sh https://github.com/AndreCostaaa/lvgl.git remove-draw-task
```

Build every configuration, or some of them by name:

```sh
sandbox/scripts/check.sh              # all
sandbox/scripts/check.sh pxp sdl      # some
sandbox/scripts/check.sh -v pxp       # print the build output
```

`check.sh` runs `zephyr.sh` and `linux.sh`, which can also be run on their own with the same options.

Build G2D (optional, needs an i.MX Yocto SDK):

```sh
sandbox/scripts/g2d.sh /opt/fsl-imx-wayland/<version>/environment-setup-armv8a-poky-linux
```

Each line of output is one configuration: `OK` (built), `OK*` (LVGL built, the build failed outside LVGL) or `FAIL`.
`warnings` counts warnings in `lvgl/src`. Logs are in `build-check/`. A script exits non-zero if anything fails.

## Configurations

Zephyr (`scripts/zephyr.sh`, configs in `conf/`):

| Name          | Draw unit                   | Board                                      | Expected          |
|---------------|-----------------------------|--------------------------------------------|-------------------|
| `pxp`         | NXP PXP                     | `mimxrt1170_evk/mimxrt1176/cm7`            | OK                |
| `dma2d`       | ST DMA2D                    | `stm32h7b3i_dk`                            | OK                |
| `dave2d`      | Renesas Dave2D              | `ek_ra8d1`                                 | OK, 3 warnings    |
| `nemagfx`     | NemaGFX + NEMA_VG           | `stm32u5g9j_dk2`                           | OK                |
| `epic`        | SiFli EPIC                  | `sf32lb52_devkit_lcd`                      | OK*               |
| `ppa`         | Espressif PPA               | `esp32p4_function_ev_board/esp32p4/hpcore` | OK                |
| `eve`         | EVE (FT81x)                 | `native_sim/native/64`                     | OK, ~400 warnings |
| `layer_debug` | SW + `LV_USE_LAYER_DEBUG`   | `native_sim/native/64`                     | OK                |
| `sw_simple`   | SW + `LV_DRAW_SW_COMPLEX=n` | `native_sim/native/64`                     | OK                |

Linux (`scripts/linux.sh`, configs in `conf/linux/`):

| Name       | Draw unit                                   | Expected |
|------------|---------------------------------------------|----------|
| `vg_lite`  | VG-Lite on the ThorVG simulator             | OK       |
| `nanovg`   | NanoVG on an EGL pbuffer, with glTF         | OK       |
| `opengles` | OpenGL ES with SDL's EGL backend, with glTF | OK       |
| `sdl`      | SDL                                         | OK       |
| `g2d`      | NXP G2D (`scripts/g2d.sh`)                  | OK       |

The expected warnings and the `epic` result come from code outside the rendering engine: unused variables in Dave2D,
macro redefinitions between the FT81x driver and the EVE library, and a missing display node on the EPIC board.

Zephyr is pinned to `v4.5.0-rc2` in `west.yml`.
