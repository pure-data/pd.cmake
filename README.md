# pd.cmake

The repository offers a set of script to facilitate the creation of [CMake](https://cmake.org/) projects to compile [Pure Data](https://puredata.info/) externals. CMake is a free, open-source and cross-platform system that allows to generate makefiles and projects for many OS and build systems and/or IDEs (Unix makefile, XCode, Visual Studio, Code::Blocks, etc.). So the goal of the pd.cmake is to offer a system that allows to easily and quickly create projects for developing and compiling Pd externals on the environment of your choice.

---

1. [Pre-required](#pre-required)
2. [Configuration](#configuration)
3. [Compilation](#compilation)
4. [Variables](#variables)
5. [Github Actions](#github-actions)
6. [See Also](#see-also)

---

## Pre-required

To compile Pure Data externals using **`pd.cmake`**, you need [CMake](https://cmake.org/) (version 3.18 or higher) and a build system or IDE (such as Unix Makefiles, Xcode, Visual Studio, MinGW, etc.). You also need the PureData installed on your machine. In your `CMakeLists.txt`, `pd.cmake` can be included as follows:

```cmake
set(PDCMAKE_FILE ${CMAKE_BINARY_DIR}/pd.cmake)
set(PDCMAKE_VERSION "v0.2.0")
if(NOT EXISTS "${PDCMAKE_FILE}")
    file(DOWNLOAD https://raw.githubusercontent.com/pure-data/pd.cmake/refs/tags/${PDCMAKE_VERSION}/pd.cmake ${PDCMAKE_FILE})
endif()
include(${PDCMAKE_FILE})
```

🔧 Note: Make sure to replace `PDCMAKE_VERSION` with the latest tag version.

## Configuration

The configuration of the CMakeLists with `pd.cmake` is pretty straight forward but depends on how you manage your project (folder, sources, dependencies, etc.). Here is an example that demonstrate the basic usage of the `pd.cmake` system:

```cmake
# Define your standard CMake header (for example):
cmake_minimum_required(VERSION 3.18)

# Include pd.cmake (1):
set(PDCMAKE_FILE ${CMAKE_BINARY_DIR}/pd.cmake)
set(PDCMAKE_VERSION "v0.2.0")
if(NOT EXISTS "${PDCMAKE_FILE}")
    file(DOWNLOAD https://raw.githubusercontent.com/pure-data/pd.cmake/refs/tags/${PDCMAKE_VERSION}/pd.cmake ${PDCMAKE_FILE})
endif()
include(${PDCMAKE_FILE})

# Declare the name of the project:
project(my_lib)

# Add one or several externals (5):
pd_add_external(obj_name1 Sources/obj1.c)
pd_add_external(obj_name2 Sources/obj2.cpp)

file(GLOB EXTERNAL_SOURCES "${CMAKE_SOURCE_DIR}/Sources/*.cpp")
pd_add_external(obj_name3 "${EXTERNAL_SOURCES}")
```

Further information:

1. The compiled externals will be output in the build folder. You can choose the folder name using: `cmake . -B build`.
2. As of Pd 0.51-0, you can compile a "double precision" version of Pure Data.  
   If you intend to use your externals in such an environment, you must also compile them with double precision by adding the following option: `-DPD_FLOATSIZE=64`.
3. For externals with multiple source files, the list must be enclosed in double quotes:
   ```cmake
   file(GLOB EXTERNAL_SOURCES "${CMAKE_SOURCE_DIR}/Sources/*.cpp")
   pd_add_external(myobj3 "${EXTERNAL_SOURCES}")


## Compilation

The generation of the build system or the IDE project is similar to any CMake project. The basic usage follows these steps from the project folder (where _CMakeLists_ is localized):

```bash
cmake . -B build
cmake --build build
```

> [!TIP]
> For big projects, you can use `cmake --build build -j4` for a parallel build. Where `4` is the number of CPUs.

## Variables

- `PDCMAKE_DIR`: Define the `PATH` where is located _pd.cmake_.
- `PD_SOURCES_PATH`: Define the `PATH` where is located `m_pd.h`.
- `PDLIBDIR`: Define the `PATH` where the externals should be installed.
- `PDBINDIR`: Define the `PATH` where is located `pd.dll` or `pd64.dll` (Just for Windows).
- `PD_FLOATSIZE`: Define the float size (32 or 64).
- `PD_INSTALL_LIBS`: Define if we must install the externals in `PDLIBDIR` or not (True or False).
- `PD_ENABLE_TILDE_TARGET_WARNING`: Enable/Disable a warning when using target name (aka Object Name) with `~` (see details on [Wiki](https://github.com/pure-data/pd.cmake/wiki)).

## Github Actions

`pd.cmake` offers an example for easily integrating GitHub Actions into your workflow (allowing automation for compiling the objects), it facilitates the compilation process for your PureData Library without the need for external resources or borrowing machines (for example). See more details on [Wiki](https://github.com/pure-data/pd.cmake/wiki).

## See Also

- [pd-lib-builder](https://github.com/pure-data/pd-lib-builder)
