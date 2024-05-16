# check if cmake version is higher than 3.19
if(${CMAKE_VERSION} VERSION_LESS "3.19")
    message(FATAL_ERROR "CMake version must be at least 3.19")
endif()

set(PD_CMAKE_PATH ${CMAKE_CURRENT_LIST_DIR})
set(PD_FLOATSIZE 32 CACHE STRING "the floatsize of Pd (32 or 64)")
set(PD_SOURCES_PATH "" CACHE PATH "Path to Pd sources")

if (APPLE)
    set(PDLIBDIR "~/Library/Pd" CACHE PATH "Path where lib will be installed")
elseif (UNIX)
    # set(PDLIBDIR "/usr/local/lib/pd-externals" CACHE PATH "Path where lib will be installed")
    set(PDLIBDIR "$ENV{HOME}/Documents/Pd/externals" CACHE PATH "Path where lib will be installed")
    # TODO: This should be for user not for root
elseif (WIN32)
    set(PDLIBDIR "$ENV{APPDATA}/Pd" CACHE PATH "Path where lib will be installed")
else()
    message(FATAL_ERROR "Platform not supported")
endif()

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

if(NOT PD_SOURCES_PATH)
    # Windows 
    if (WIN32)
        if (PD_FLOATSIZE EQUAL 64)
            set(PD_SOURCES_PATH "C:/Program Files/Pd64/src")
            if (NOT PDBINDIR)
                set(PDBINDIR "C:/Program Files/Pd64/bin")
            endif()
        elseif (PD_FLOATSIZE EQUAL 32)
            set(PD_SOURCES_PATH "C:/Program Files/Pd/src")
            if (NOT PDBINDIR)
                set(PDBINDIR "C:/Program Files/Pd/bin")
            endif()
        endif()
        find_library(PD_LIBRARY NAMES pd HINTS ${PDBINDIR})
        find_path(PD_HEADER_PATH m_pd.h PATHS ${PD_SOURCES_PATH})
        if (NOT PD_HEADER_PATH)
            message(FATAL_ERROR "<m_pd.h> not found in C:\\Program Files\\Pd\\src, is Pd installed?")
        endif()

        find_library(PD_LIBRARY NAMES pd HINTS ${PDBINDIR})

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
        if(NOT PDBINDIR)
            set(PDBINDIR ${PD_SOURCES_PATH}/../bin)
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
    set(PD_SOURCES_PATH ${PD_SOURCES_PATH})

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
function(install_libs OBJ_NAME)
    if (PD_INSTALL_LIBS)
        if(NOT EXISTS ${PDLIBDIR})
            file(MAKE_DIRECTORY ${PDLIBDIR})
        endif()
        # if (PD_INSTALL_LIBS) # TODO: Add this
            get_property(LOCAL_DATA_FILES TARGET ${OBJ_NAME} PROPERTY EXTERNAL_DATA_FILES)
            foreach(DATA_FILE ${LOCAL_DATA_FILES})
                get_filename_component(DATA_FILE ${DATA_FILE} ABSOLUTE)
                get_filename_component(FILE_NAME ${DATA_FILE} NAME)

                add_custom_command(
                    TARGET ${OBJ_NAME} POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E make_directory ${PDLIBDIR}/${PROJECT_NAME}
                    COMMAND ${CMAKE_COMMAND} -E copy ${DATA_FILE} ${PDLIBDIR}/${PROJECT_NAME}/${FILE_NAME}
                )
            endforeach()
    endif()
endfunction(install_libs)

# ──────────────────────────────────────
function (add_datafile OBJ_NAME DATA_FILE)
    if(${OBJ_NAME} MATCHES "~$")
        string(REGEX REPLACE "~$" "_tilde" OBJ_PROJECT_NAME ${OBJ_NAME})
    else()
        set(OBJ_PROJECT_NAME ${OBJ_NAME})
    endif()

    get_property(LOCAL_DATA_FILES TARGET ${OBJ_PROJECT_NAME} PROPERTY EXTERNAL_DATA_FILES)
    list(APPEND LOCAL_DATA_FILES ${DATA_FILE})
    set_property(TARGET ${OBJ_PROJECT_NAME} PROPERTY EXTERNAL_DATA_FILES ${LOCAL_DATA_FILES})
    get_property(LOCAL_DATA_FILES TARGET ${OBJ_PROJECT_NAME} PROPERTY EXTERNAL_DATA_FILES)
endfunction(add_datafile)

# ──────────────────────────────────────
function(set_pd_lib_ext OBJ_PROJECT_NAME)
    if(PD_EXTENSION)
        set_target_properties(${OBJ_PROJECT_NAME} PROPERTIES SUFFIX ".${PD_EXTENSION}")
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
        endif()
        set_target_properties(${OBJ_PROJECT_NAME} PROPERTIES SUFFIX ${PD_EXTENSION})
    endif()
endfunction(set_pd_lib_ext)

# ──────────────────────────────────────
function(set_compiler_flags OBJ_PROJECT_NAME)
    if (WIN32)
        if (PD_FLOATSIZE EQUAL 64)
            target_link_libraries(${OBJ_PROJECT_NAME} "${PDBINDIR}/pd64.lib")
        elseif (PD_FLOATSIZE EQUAL 32)
            target_link_libraries(${OBJ_PROJECT_NAME} "${PDBINDIR}/pd.lib")
        endif()
    elseif (APPLE)
        set_target_properties(${OBJ_PROJECT_NAME} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
    endif()
endfunction(set_compiler_flags)

# ──────────────────────────────────────
function(add_pd_external EXTERNAL_NAME EXTERNAL_SOURCES)
    # check if thereis ~ in OBJ_NAME, if yes, replace it with _tilde
    if(${EXTERNAL_NAME} MATCHES "~$")
        string(REGEX REPLACE "~$" "_tilde" OBJ_PROJECT_NAME ${EXTERNAL_NAME})
    else()
        set(OBJ_PROJECT_NAME ${EXTERNAL_NAME})
    endif()

    # print a new line

    set(ALL_SOURCES ${EXTERNAL_SOURCES}) 
    list(APPEND ALL_SOURCES ${ARGN})
    source_group(src FILES ${ALL_SOURCES})
    add_library(${OBJ_PROJECT_NAME} SHARED ${ALL_SOURCES})
	set_target_properties(${OBJ_PROJECT_NAME} PROPERTIES PREFIX "")
    set_property(TARGET ${OBJ_PROJECT_NAME} PROPERTY EXTERNAL_DATA_FILES "")

	target_include_directories(${OBJ_PROJECT_NAME} PRIVATE ${PD_SOURCES_PATH})
	set_target_properties(${OBJ_PROJECT_NAME} PROPERTIES OUTPUT_NAME ${EXTERNAL_NAME})

	# Defines the output path of the external.
  	set_target_properties(${OBJ_PROJECT_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
	set_target_properties(${OBJ_PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
	set_target_properties(${OBJ_PROJECT_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

	foreach(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
		    string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG)
			set_target_properties(${OBJ_PROJECT_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR})
			set_target_properties(${OBJ_PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR})
			set_target_properties(${OBJ_PROJECT_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR})
	endforeach(OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES)

    set_pd_lib_ext(${OBJ_PROJECT_NAME})
    set_compiler_flags(${OBJ_PROJECT_NAME})
    get_property(PD_EXTENSION TARGET ${OBJ_PROJECT_NAME} PROPERTY SUFFIX)
    
    if(PD_FLOATSIZE STREQUAL 64)
        target_compile_definitions(${OBJ_PROJECT_NAME} PRIVATE PD_FLOATSIZE=64)
    endif()

    add_datafile(${OBJ_PROJECT_NAME} ${CMAKE_BINARY_DIR}/${EXTERNAL_NAME}${PD_EXTENSION})
    cmake_language(EVAL CODE
        "cmake_language(DEFER CALL install_libs [[${OBJ_PROJECT_NAME}]])"
    )
endfunction(add_pd_external)


