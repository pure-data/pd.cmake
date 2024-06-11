# Define your standard CMake header (for example):
cmake_minimum_required(VERSION 3.15)
set(PDCMAKE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../ CACHE PATH "Path to pd.cmake")
include(${PDCMAKE_DIR}/pd.cmake)
project(mysimplelib)

# Obj 0 - Just a simple object
# add_pd_external(simple simple ${CMAKE_SOURCE_DIR}/simple/simple.cpp) 

# Obj 1
pd_add_external(simple ${CMAKE_SOURCE_DIR}/simple/simple.cpp CXX_FLAGS -std=c++11 -Wall C_FLAGS -Wall)
pd_add_datafile(simple "${CMAKE_SOURCE_DIR}/simple/simple-help.pd")

# Obj 2
# pd_add_external(simple~ ${CMAKE_SOURCE_DIR}/simple~/simple~.cpp 
#         TARGET simple_tilde)
# pd_add_datafile(simple_tilde "${CMAKE_SOURCE_DIR}/simple~/simple~-help.pd")
