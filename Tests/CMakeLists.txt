# Define your standard CMake header (for example):
cmake_minimum_required(VERSION 3.15)
project(Tests)

add_subdirectory(01.Deprecated-Functions)



pd_add_external(simple ${CMAKE_SOURCE_DIR}/../Examples/simple/simple.cpp) 
pd_add_datafile(simple "${CMAKE_SOURCE_DIR}/../Examples/simple/simple-help.pd")

# Obj 2
pd_add_external(simple~ ${CMAKE_SOURCE_DIR}/../Examples/simple~/simple~.cpp 
        TARGET simple_tilde)
pd_add_datafile(simple_tilde "${CMAKE_SOURCE_DIR}/../Examples/simple~/simple~-help.pd")


# add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../Examples/)
