# Define your standard CMake header (for example):
cmake_minimum_required(VERSION 3.15)
set(PDCMAKE_DIR ${CMAKE_SOURCE_DIR}/../ CACHE PATH "Path to pd.cmake")
include(${PDCMAKE_DIR}/pd.cmake)

project(deprecatedfunctions)

# Obj 0 - Just a simple object
add_pd_external(deprecated_simple simple ${CMAKE_SOURCE_DIR}/../Examples/simple/simple.cpp) 

