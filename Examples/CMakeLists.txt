# Define your standard CMake header (for example):
cmake_minimum_required(VERSION 3.15)
set(PDCMAKE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../ CACHE PATH "Path to pd.cmake")
include(${PDCMAKE_DIR}/pd.cmake)

# Simple Obj 1
project(mysimplelib)
add_pd_external(simple ${CMAKE_SOURCE_DIR}/simple/simple.cpp)

file(GLOB HELP_PATCHES "${CMAKE_SOURCE_DIR}/simple/*.pd")
add_datafile(simple ${HELP_PATCHES})


# Simple Obj 2
add_pd_external(simple~ ${CMAKE_SOURCE_DIR}/simple~/simple~.cpp)
add_datafile(simple~ "${CMAKE_SOURCE_DIR}/simple~/simple~-help.pd")

