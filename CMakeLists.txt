# Define your standard CMake header (for example):
cmake_minimum_required(VERSION 3.15)
include(${CMAKE_CURRENT_SOURCE_DIR}/pd.cmake)

# Simple Obj 1
project(mysimplelib)
add_pd_external(obj1 simple ${CMAKE_SOURCE_DIR}/Examples/simple/simple.cpp)

# Simple Obj 2
add_pd_external(obj2 simple~ ${CMAKE_SOURCE_DIR}/Examples/simple~/simple~.cpp)
