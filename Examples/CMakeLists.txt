# Define your standard CMake header (for example):
cmake_minimum_required(VERSION 3.15)
set(PDCMAKE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../ CACHE PATH "Path to pd.cmake")
include(${PDCMAKE_DIR}/pd.cmake)
project(mysimplelib)

# Obj 1 - Simple obj
pd_add_external(simple ${CMAKE_SOURCE_DIR}/simple/simple.cpp) 
pd_add_datafile(simple "${CMAKE_SOURCE_DIR}/simple/simple-help.pd")

# Obj 2 - Simple obj - two inlets
pd_add_external(sum ${CMAKE_SOURCE_DIR}/sum/sum.cpp) 

# Obj 3 - Simple DSP obj
pd_add_external(simple~ ${CMAKE_SOURCE_DIR}/simple~/simple~.cpp 
        TARGET simple_tilde)
pd_add_datafile(simple_tilde "${CMAKE_SOURCE_DIR}/simple~/simple~-help.pd")

# Obj 4 - Simple DSP obj with dynamic library
pd_add_external(myfft~ ${CMAKE_SOURCE_DIR}/fft~/fft~.cpp 
        TARGET myfft_tilde)
target_link_libraries(myfft_tilde fftw3f)
