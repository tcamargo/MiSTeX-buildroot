# MiSTeX buildroot

# Table of Contents
1. [Requirements](#requirements)
1. [Building](#building)
    1. [Create docker image](#docker)
    1. [Compiling](#compiling)
    1. [Flashing](#flashing)
    1. [Useful targets](#targets)

Creates the SD card image for the Linux root filesystem of MiSTeX and SDK for building the main executable.

## Requirements

- Any modern linux distro.
- Docker
- git
- ~25GB of disk space

Instructions to install  packages varies. Consult your distro documentation.

## Building

### Create docker image <a id="docker"></a>

All build process is done inside a docker container. A Dockerfile is available for you to build the image yourself. You only have to do it once or when a change in image was necessary.

```
make build-docker-image
```

###  Compiling

You can build as root or allow your user to use docker without sudo. Your choice.

Currently, we support the following boards:

| Board | Target Prefix | 
| - | - | 
| OrangePi Zero 2w | orangepi-zero-2w |

You need to specify the target prefix in every make command from now on. Examples will use the OrangePi Zero 2w target. Adapt accordingly.

```
make orangepi-zero-2w-build
``` 

Sit back and enjoy your favorite beverage. It will take a while to bootstrap the toolchain and build all necessary packages.

In case you have an unstable network connection, it might be good to download all source packages in advance.

```
make orangepi-zero-2w-source
``` 

### Flashing

WIP

### Useful targets <a id="targets"></a>

|  | Target | 
| - | - | 
| Clean build | ` make <target preix>-clean ` |
| Buildroot menu | ` make orangepi-zero-2w-build CMD=menuconfig ` |
| Build single package | ` make <target preix>-pkg PKG=<package> ` |
| Clean package directory | ` make <target preix>-pkg PKG=<package>-dirclean ` |
| Kernel menu | ` make orangepi-zero-2w-pkg PKG=linux-menuconfig ` |
| U-Boot menu | ` make orangepi-zero-2w-pkg PKG=uboot-menuconfig ` |

See [Package-specific make targets](https://buildroot.org/downloads/manual/manual.html#pkg-build-steps) for more -pkg options.

