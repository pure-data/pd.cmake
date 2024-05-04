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

To compile Pd externals using _pd.cmake_, you need [CMake](https://cmake.org/) (minimum version 3.15) and a build system or an IDE (like Unix makefile, XCode, Visual Studio, Code::Blocks, etc.). You also need the Pure Data sources, that are generally included within your Pure Data distribution and [pd.cmake](https://github.com/pure-data/pd.build/archive/main.zip). If you use [Git](https://git-scm.com/) to manage your project, it is reccommend to include `pd.cmake` as a submodule `git submodule add https://github.com/pure-data/pd.cmake`.

## Configuration

The configuration of the CMakeList with pd.cmake is pretty straight forward but depends on how you manage your project (folder, sources, dependencies, etc.). Here is an example that demonstrate the basic usage of the pd.cmake system:

```cmake
# Define your standard CMake header (for example):
cmake_minimum_required(VERSION 3.15)

# Include pd.cmake (1):
include(${CMAKE_CURRENT_SOURCE_DIR}/pd.cmake/pd.cmake)

# Declare the name of the project:
project(my_objects)

# Add one or several externals (5):
add_pd_external(myobj1 obj_name1 ${CMAKE_CURRENT_SOURCE_DIR}/Sources/obj1.c)

add_pd_external(myobj2 obj_name2 ${CMAKE_CURRENT_SOURCE_DIR}/Sources/obj2.cpp)
```

Further information:

1. The path _pd.cmake_ depends on where you installed _pd.cmake, here we assume that \_pd.cmake_ is localized at the root directory of you project.
2. Here the externals are installed in the _Binaries_ folder, you can change it using `set_pd_external_path(PATH)`.
3. As of Pd 0.51-0 you can compile a ["Double precision" Pd](http://msp.ucsd.edu/Pd_documentation/x6.htm#s6.6). If you intend to use your externals in such an environment, you must also compile them with double precision by adding this line `.
4. The function adds a new subproject to the main project. This subproject matches to a new external allowing to compile only one object without compiling all the others. The first argument is the name of the subproject, the second argument is the name of the external and the third argument are the sources. If you use more than one file, you can use `GLOB`, in this case, we compile all `.cpp` files inside `Sources`.

```cmake
file(GLOB EXTERNAL_SOURCES "${CMAKE_SOURCE_DIR}/Sources/*.cpp")
add_pd_external(myobj3 myobj3 ${EXTERNAL_SOURCES})
```

## Compilation

The generation of the build system or the IDE project is similar to any CMake project. The basic usage follows these steps from the project folder (where _CMakeList_ is localized):

```bash
cmake . -B build
cmake --build build
```

> [!TIP]
> For big projects, you can use `cmake --build build -j4` for parallel build. Where `4` is the number of CPUs.

## Github Actions

`pd.cmake` offers an example for easily integrating GitHub Actions into your workflow, it facilitates the compilation process for your PureData Library without the need for external resources or borrowing machines (for example).

<details><summary>How to use for your Library</summary>

1. Create Necessary Folders:
    * Navigate to your Library Folder.
    * Create a new folder named `.github`.
    * Within `.github`, create another folder named `workflows`.

2. Download Example File:
    * Download the provided example file from this link [here](https://raw.githubusercontent.com/pure-data/pd.cmake/main/.github/workflows/c-cpp.yml).
    * Paste the downloaded file into the workflows folder you just created.
3. Modify Variables:
    * Open the downloaded file.
    * Find the variable `LIBNAME` on line 09.
    * Replace `simple` with the name of your library.
4. Commit and Upload:
    * Commit the changes to your repository on GitHub.
5. Run Workflow:
    * Go to the Actions tab on your GitHub repository page.
    * Look for an action called `C/C++ CI` (if you don't changed the name).
    * Click on it, then click Run workflow.
    * Wait for the workflow to complete.
6. Download Result:
    * After the workflow has finished running, refresh the page.
    * Look for a new item, usually titled with the last commit message.
    * If you see a blue checkbox, click on it.
    * Scroll down and locate a file named `yourlibname-ALL-binaries`.
    * Download this file.

If the workflow fails (you see a red `x` instead of a checkbox), you'll need to debug. You can seek help in the issues section of the `pd.cmake` repository.

#### About Dynamic Libraries

If you use `fftw3` in your object or anything else, you will need to install it. There is indications in the `c-cpp.yml` where you add this, for Windows, prefer `mingw64` build for now.

</details>


## See Also

- [pd-lib-builder](https://github.com/pure-data/pd-lib-builder)

