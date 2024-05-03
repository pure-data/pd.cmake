set(PD_CMAKE_PATH ${CMAKE_CURRENT_LIST_DIR})
set(PD_OUTPUT_PATH)
set(PD_FLOATSIZE 32 CACHE STRING "the floatsize of Pd (32 or 64)")

#╭──────────────────────────────────────╮
#│                Macros                │
#╰──────────────────────────────────────╯
macro(set_pd_external_path EXTERNAL_PATH)
	set(PD_OUTPUT_PATH ${EXTERNAL_PATH})
endmacro(set_pd_external_path)

# ──────────────────────────────────────
# The macro sets the location of Pure Data sources.
macro(set_pd_sources PD_SOURCES)
	set(PD_SOURCES_PATH ${PD_SOURCES})
endmacro(set_pd_sources)

#╭──────────────────────────────────────╮
#│              Functions               │
#╰──────────────────────────────────────╯
function(set_pd_lib_path)
    if(NOT PD_SOURCES_PATH)
        if (WIN32)
            set(PD_SOURCES_PATH "C:\\Program Files\\Pd\\src")
            set(PD_LIB_PATH "C:\\Program Files\\Pd\\bin")
            find_path(PD_HEADER_PATH m_pd.h PATHS ${PD_SOURCES_PATH})
            find_library(PD_LIBRARY pd PATHS ${PD_LIBRARY_PATH})
            if (NOT PD_HEADER_PATH)
                message(FATAL_ERROR "<m_pd.h> not found in C:\\Program Files\\Pd\\src, is Pd installed?")
            endif()
            if (NOT PD_LIBRARY)
                message(FATAL_ERROR "'pd.dll' not found in C:\\Program Files\\Pd\\bin, is Pd installed?")
            endif()
        endif()
        if(APPLE)
            file(GLOB PD_INSTALLER "/Applications/Pd*.app")
            if(PD_INSTALLER)
                foreach(app ${PD_INSTALLER})
                    get_filename_component(PD_SOURCES_PATH "${app}/Contents/Resources/src/" ABSOLUTE)
                endforeach()
            else()
                message(FATAL_ERROR "PD_SOURCES_PATH not set and no Pd.app found in /Applications, is Pd installed?")
            endif()
            message(STATUS "PD_SOURCES_PATH not set, using ${PD_SOURCES_PATH}")
            set(PD_SOURCES_PATH ${PD_SOURCES_PATH})
        endif()
        if (UNIX)
            if(NOT PD_SOURCES_PATH)
                set(PD_SOURCES_PATH "/usr/include/pd/")
            endif()
			if(NOT PD_LIB_PATH)
            	set(PD_LIB_PATH ${PD_SOURCES_PATH}/../bin)
			endif()
        endif()
	endif()
endfunction(set_pd_lib_path)

# ──────────────────────────────────────
function(set_pd_lib_ext)
    if(PD_EXTENSION)
        set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".${PD_EXTENSION}")
    else()
        if (NOT (PD_FLOATSIZE EQUAL 64 OR PD_FLOATSIZE EQUAL 32))
            message(FATAL_ERROR "PD_FLOATSIZE must be 32 or 64")
        endif()
        if(APPLE)
            if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
                set(PD_EXTENSION ".darwin-arm64-${PD_FLOATSIZE}.dylib")
            else()
                set(PD_EXTENSION ".darwin-amd64-${PD_FLOATSIZE}.dylib")
            endif()
        elseif(UNIX)
            if(CMAKE_SIZEOF_VOID_P EQUAL 4)
                if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
                    set(PD_EXTENSION ".linux-arm-${PD_FLOATSIZE}.so")
                endif()
            else()
                if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
                    set(PD_EXTENSION ".linux-arm64-${PD_FLOATSIZE}.so")
                else()
                    set(PD_EXTENSION ".linux-amd64-${PD_FLOATSIZE}.so")
                endif()
            endif()
        elseif(WIN32)
            if(CMAKE_SIZEOF_VOID_P EQUAL 4)
                set(PD_EXTENSION ".windows-i386-${PD_FLOATSIZE}.dll")
            else()
                set(PD_EXTENSION ".windows-amd64-${PD_FLOATSIZE}.dll")
            endif()
        endif()
        if (NOT PD_EXTENSION)
            message(FATAL_ERROR "Not possible to determine the extension of the library, please set PD_EXTENSION")
        endif()
        set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ${PD_EXTENSION})
    endif()
endfunction(set_pd_lib_ext)

# ──────────────────────────────────────
function(add_pd_external PROJECT_NAME EXTERNAL_NAME EXTERNAL_SOURCES)
    if (NOT PD_OUTPUT_PATH)
        set(PD_OUTPUT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/PdObj)
    endif()

    set(ALL_SOURCES ${EXTERNAL_SOURCES}) 
    list(APPEND ALL_SOURCES ${ARGN})
    source_group(src FILES ${ALL_SOURCES})
    add_library(${PROJECT_NAME} SHARED ${ALL_SOURCES})
	set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")
	target_include_directories(${PROJECT_NAME} PRIVATE ${PD_SOURCES_PATH})
	set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME ${EXTERNAL_NAME})
	set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME ${EXTERNAL_NAME})

	# Defines the output path of the external.
  	set_target_properties(${PROJECT_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${PD_OUTPUT_PATH})
	set_target_properties(${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${PD_OUTPUT_PATH})
	set_target_properties(${PROJECT_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY ${PD_OUTPUT_PATH})
	foreach(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
		    string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG)
			set_target_properties(${PROJECT_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${PD_OUTPUT_PATH})
			set_target_properties(${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${PD_OUTPUT_PATH})
			set_target_properties(${PROJECT_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${PD_OUTPUT_PATH})
	endforeach(OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES)

    set_pd_lib_path()
    set_pd_lib_ext()

    if(PD_FLOATSIZE STREQUAL 64)
        target_compile_definitions(${PROJECT_NAME} PRIVATE PD_FLOATSIZE=64)
    endif()

    # TODO: Add MSVC support

endfunction(add_pd_external)

