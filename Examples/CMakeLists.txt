# set minimal version of cmake
cmake_minimum_required(VERSION 3.15) 

# import pd.cmake file
set(PDCMAKE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../ CACHE PATH "Path to pd.cmake")
include(${PDCMAKE_DIR}/pd.cmake)

#╭──────────────────────────────────────╮
#│   define the name of your project,   │
#│  when using -DPD_INSTALL_LIBS=True   │
#│ this will be the name of the folder  │
#│ of your library. For example, else,  │
#│           cyclone, etc...            │
#╰──────────────────────────────────────╯
project(mysimplelib)


#╭──────────────────────────────────────╮
#│          Obj 1 - Simple obj          │
#╰──────────────────────────────────────╯
pd_add_external(simple ${CMAKE_SOURCE_DIR}/simple/simple.cpp) 
pd_add_datafile(simple "${CMAKE_SOURCE_DIR}/simple/simple-help.pd")

#╭──────────────────────────────────────╮
#│        Obj 2 - Simple DSP obj        │
#╰──────────────────────────────────────╯
pd_add_external(simple~ ${CMAKE_SOURCE_DIR}/simple~/simple~.cpp 
        TARGET simple_tilde)
pd_add_datafile(simple_tilde "${CMAKE_SOURCE_DIR}/simple~/simple~-help.pd")

#╭──────────────────────────────────────╮
#│ Obj 3 - Simple DSP obj with dynamic  │
#│           library (fftw3f)           │
#╰──────────────────────────────────────╯
# NOTE: You need to have fftw3f installed in your system
pd_add_external(myfft~ ${CMAKE_SOURCE_DIR}/fft~/fft~.cpp 
        TARGET myfft_tilde)
pd_add_datafile(simple "${CMAKE_SOURCE_DIR}/fft~/fft~-help.pd")
target_link_libraries(myfft_tilde PRIVATE fftw3f) # Link with fftw3f library
