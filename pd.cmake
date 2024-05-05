set(PD_CMAKE_PATH ${CMAKE_CURRENT_LIST_DIR})
set(PD_OUTPUT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/Binaries CACHE PATH "Path to the output of the external")
set(PD_FLOATSIZE 32 CACHE STRING "the floatsize of Pd (32 or 64)")
set(PD_SOURCES_PATH "" CACHE PATH "Path to Pd sources")

#╭──────────────────────────────────────╮
#│   ToolChain for Raspberry (others)   │
#│               and ARM                │
#╰──────────────────────────────────────╯

if (CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    set(CMAKE_SYSTEM_NAME Linux)
    set(CMAKE_SYSTEM_PROCESSOR aarch64)
    find_program(AARCH64_GCC NAMES aarch64-linux-gnu-gcc)
    find_program(AARCH64_GXX NAMES aarch64-linux-gnu-g++)
    if(AARCH64_GCC AND AARCH64_GXX)
        set(CMAKE_C_COMPILER ${AARCH64_GCC})
        set(CMAKE_CXX_COMPILER ${AARCH64_GXX})
    else()
        message(FATAL_ERROR "Cross-compilers for aarch64 architecture not found.")
    endif()
elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
    set(CMAKE_SYSTEM_NAME Linux)
    set(CMAKE_SYSTEM_PROCESSOR arm)
    find_program(ARM_GCC NAMES arm-linux-gnueabihf-gcc)
    find_program(ARM_GXX NAMES arm-linux-gnueabihf-g++)
    if(ARM_GCC AND ARM_GXX)
        set(CMAKE_C_COMPILER ${ARM_GCC})
        set(CMAKE_CXX_COMPILER ${ARM_GXX})
    else()
        message(FATAL_ERROR "ERROR: Cross-compilers for ARM architecture not found.")
    endif()
endif()

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
function(set_pd_paths)
    if(NOT PD_SOURCES_PATH)
        # Windows 
        if (WIN32)
            if (PD_FLOATSIZE EQUAL 64)
                set(PD_SOURCES_PATH "C:/Program Files/Pd64/src")
                set(PD_LIB_PATH "C:/Program Files/Pd64/bin")
            elseif (PD_FLOATSIZE EQUAL 32)
                set(PD_SOURCES_PATH "C:/Program Files/Pd/src")
                set(PD_LIB_PATH "C:/Program Files/Pd/bin")
            endif()
		    find_library(PD_LIBRARY NAMES pd HINTS ${PD_LIB_PATH})
            find_path(PD_HEADER_PATH m_pd.h PATHS ${PD_SOURCES_PATH})
            if (NOT PD_HEADER_PATH)
                message(FATAL_ERROR "<m_pd.h> not found in C:\\Program Files\\Pd\\src, is Pd installed?")
            endif()

            find_library(PD_LIBRARY NAMES pd HINTS ${PD_LIB_PATH})
            if (PD_FLOATSIZE EQUAL 64)
                target_link_libraries(${PROJECT_NAME} "${PD_LIB_PATH}/pd64.lib")
            elseif (PD_FLOATSIZE EQUAL 32)
                target_link_libraries(${PROJECT_NAME} "${PD_LIB_PATH}/pd.lib")
            endif()

        #  macOS
        elseif(APPLE)
            file(GLOB PD_INSTALLER "/Applications/Pd*.app")
            if(PD_INSTALLER)
                foreach(app ${PD_INSTALLER})
                    get_filename_component(PD_SOURCES_PATH "${app}/Contents/Resources/src/" ABSOLUTE)
                endforeach()
            else()
                message(FATAL_ERROR "PD_SOURCES_PATH not set and no Pd.app found in /Applications, is Pd installed?")
            endif()

            find_path(PD_HEADER_PATH m_pd.h PATHS ${PD_SOURCES_PATH})
            if (NOT PD_HEADER_PATH)
                message(FATAL_ERROR "<m_pd.h> not found in /Applications/Pd.app/Contents/Resources/src/, is Pd installed?")
            endif()
            message(STATUS "PD_SOURCES_PATH not set, using ${PD_SOURCES_PATH}")

        # Linux
        elseif (UNIX)
            if(NOT PD_SOURCES_PATH)
                set(PD_SOURCES_PATH "/usr/include/pd/")
            endif()
			if(NOT PD_LIB_PATH)
            	set(PD_LIB_PATH ${PD_SOURCES_PATH}/../bin)
			endif()

            find_path(PD_HEADER_PATH m_pd.h PATHS ${PD_SOURCES_PATH})
            if (NOT PD_HEADER_PATH)
                message(FATAL_ERROR "<m_pd.h> not found in /usr/include/pd/, is Pd installed?")
            endif()

        # Unknown
        else()
            message(FATAL_ERROR "PD_SOURCES_PATH not set and no default path for the system")
        endif()

        # Set the paths
        set(PD_SOURCES_PATH ${PD_SOURCES_PATH} PARENT_SCOPE)

	endif()
endfunction(set_pd_paths)

# ──────────────────────────────────────
function(set_pd_lib_ext)
    if(PD_EXTENSION)
        set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".${PD_EXTENSION}")
    else()
        if (NOT (PD_FLOATSIZE EQUAL 64 OR PD_FLOATSIZE EQUAL 32))
            message(FATAL_ERROR "PD_FLOATSIZE must be 32 or 64")
        endif()

        if(APPLE)
            if (CMAKE_OSX_ARCHITECTURES MATCHES "arm64")
                set(PD_EXTENSION ".darwin-arm64-${PD_FLOATSIZE}.so")
            else()
                set(PD_EXTENSION ".darwin-amd64-${PD_FLOATSIZE}.so")
            endif()

        elseif(UNIX)
            if(CMAKE_SIZEOF_VOID_P EQUAL 4) # 32-bit
                if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
                    set(PD_EXTENSION ".linux-arm-${PD_FLOATSIZE}.so")
                endif()
            else()
                if (CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
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
        else()
            message(STATUS "Extension for ${PROJECT_NAME} library is ${PD_EXTENSION}")
        endif()
        set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ${PD_EXTENSION})
    endif()
endfunction(set_pd_lib_ext)

# ──────────────────────────────────────
function(set_compiler_flags)
    if (APPLE)
		set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
    endif()
endfunction(set_compiler_flags)

# ──────────────────────────────────────
function(add_pd_external PROJECT_NAME EXTERNAL_NAME EXTERNAL_SOURCES)
    set(ALL_SOURCES ${EXTERNAL_SOURCES}) 
    list(APPEND ALL_SOURCES ${ARGN})
    source_group(src FILES ${ALL_SOURCES})
    add_library(${PROJECT_NAME} SHARED ${ALL_SOURCES})
	set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")

    set_pd_paths()
  
	target_include_directories(${PROJECT_NAME} PRIVATE ${PD_SOURCES_PATH})
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

    set_pd_lib_ext()
    set_compiler_flags()

    if(PD_FLOATSIZE STREQUAL 64)
        target_compile_definitions(${PROJECT_NAME} PRIVATE PD_FLOATSIZE=64)
    endif()
endfunction(add_pd_external)

