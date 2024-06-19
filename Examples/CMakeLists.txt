# set minimal version of cmake
cmake_minimum_required(VERSION 3.18) 

#╭──────────────────────────────────────╮
#│   define the name of your project,   │
#│  when using -DPD_INSTALL_LIBS=True   │
#│ this will be the name of the folder  │
#│ of your library. For example, else,  │
#│           cyclone, etc...            │
#╰──────────────────────────────────────╯
project(examples) 

# import pd.cmake file
set(PDCMAKE_DIR ../ CACHE PATH "Path to pd.cmake")
include(${PDCMAKE_DIR}/pd.cmake)

#╭──────────────────────────────────────╮
#│          Obj 1 - Simple obj          │
#╰──────────────────────────────────────╯
pd_add_external(simple simple/simple.cpp) 
pd_add_datafile(simple simple/simple-help.pd)

#╭──────────────────────────────────────╮
#│        Obj 2 - Simple DSP obj        │
#╰──────────────────────────────────────╯
pd_add_external(simple~ simple~/simple~.cpp 
        TARGET simple_tilde)
pd_add_datafile(simple_tilde simple~/simple~-help.pd)

#╭──────────────────────────────────────╮
#│ Obj 3 - Simple DSP obj with dynamic  │
#│           library (fftw3f)           │
#╰──────────────────────────────────────╯
# NOTE: You need to have fftw3f installed in your system
pd_add_external(myfft~ fft~/fft~.cpp TARGET myfft_tilde)
pd_add_datafile(myfft_tilde fft~/fft~-help.pd)
target_link_libraries(myfft_tilde PRIVATE fftw3f) # Link with fftw3f library
