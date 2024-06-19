# pd.cmake

The repository offers a set of script to facilitate the creation of [CMake](https://cmake.org/) projects to compile [Pure Data](https://puredata.info/) externals. CMake is a free, open-source and cross-platform system that allows to generate makefiles and projects for many OS and build systems and/or IDEs (Unix makefile, XCode, Visual Studio, Code::Blocks, etc.). So the goal of the pd.cmake is to offer a system that allows to easily and quickly create projects for developing and compiling Pd externals on the environment of your choice.

---

1. [Pre-required](https://github.com/pure-data/pd.cmake#pre-required)
2. [Configuration](https://github.com/pure-data/pd.cmake#Configuration)
3. [Generation](https://github.com/pure-data/pd.cmake#Generation)
4. [Github Actions](https://github.com/pure-data/pd.cmake#Github-Actions)
5. [Examples](https://github.com/pure-data/pd.cmake#Examples)
6. [See Also](https://github.com/pure-data/pd.cmake#See-Also)

---

## Pre-required

To compile Pd externals using _pd.cmake_, you need [CMake](https://cmake.org/) (minimum version 3.18) and a build system or an IDE (like Unix MakeFile, XCode, Visual Studio, mingw64, etc.). You also need the Pure Data Sources, which are included within your Pure Data distribution and pd.cmake. If you use [Git](https://git-scm.com/) to manage your project, it is recommended to include `pd.cmake` as a submodule `git submodule add https://github.com/pure-data/pd.cmake`.

## Configuration

The configuration of the CMakeLists with pd.cmake is pretty straight forward but depends on how you manage your project (folder, sources, dependencies, etc.). Here is an example that demonstrate the basic usage of the `pd.cmake` system:

```cmake
# Define your standard CMake header (for example):
cmake_minimum_required(VERSION 3.18)

# Include pd.cmake (1):
set(PDCMAKE_DIR pd.cmake/ CACHE PATH "Path to pd.cmake")
include(${PDCMAKE_DIR}/pd.cmake)

# Declare the name of the project:
project(my_lib)

# Add one or several externals (5):
pd_add_external(obj_name1 Sources/obj1.c)

pd_add_external(obj_name2 Sources/obj2.cpp)
```

Further information:

1. The path _pd.cmake_ depends on where you installed _pd.cmake, here we assume that \_pd.cmake_ is localized at the root directory of you project.
2. The compiled externals will be outputed in the build folder. When can choose the folder name using `cmake . -B MY_OUTPUT_FOLDER`.
3. As of Pd 0.51-0 you can compile a "Double precision" Pd. If you intend to use your externals in such an environment, you must also compile them with double precision by adding this line `-DPD_FLOATSIZE=64`.
4. The function adds a new subproject to the main project. This subproject matches to a new external allowing to compile only one object without compiling all the others. The first argument is the name of the object (used as TARGET name) and the third argument are the sources. If you use more than one file, you can use `GLOB`, in this case, we compile all `.cpp` files inside `Sources`.

```cmake
file(GLOB EXTERNAL_SOURCES "${CMAKE_SOURCE_DIR}/Sources/*.cpp")
pd_add_external(myobj3 ${EXTERNAL_SOURCES})
```

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
