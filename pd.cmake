# check if cmake version is higher than 3.19, we need cmake_language
if(${CMAKE_VERSION} VERSION_LESS "3.19")
    message(FATAL_ERROR "pd.cmake requires Cmake Version 3.19 or newer")
endif()

include(CheckCXXSourceCompiles)

# ╭──────────────────────────────────────╮
# │                Macros                │
# ╰──────────────────────────────────────╯
macro(set_pd_external_path EXTERNAL_PATH)
    message(
        DEPRECATION
            "set_pd_external_path was removed, you can set PDLIBDIR and run cmake with '-DPD_INSTALL_LIBS=ON' instead"
    )
endmacro(set_pd_external_path)

# ──────────────────────────────────────
macro(set_pd_sources PD_SOURCES)
    message(DEPRECATION "set_pd_sources is deprecated, use pd_set_sources instead")
endmacro(set_pd_sources)

macro(pd_set_sources PD_SOURCES)
    set(PD_SOURCES_PATH ${PD_SOURCES})
endmacro(pd_set_sources)

# ╭──────────────────────────────────────╮
# │              Functions               │
# ╰──────────────────────────────────────╯
function(pd_add_datafile OBJ_TARGET DATA_FILE)
    set(BOOLEAN_ARGS)
    set(ONE_ARGS)
    set(MULTI_ARGS DESTINATION IGNORE_DIR)
    cmake_parse_arguments(PD_DATAFILE "${BOOLEAN_ARGS}" "${ONE_ARGS}" "${MULTI_ARGS}" ${ARGN})

    if(${OBJ_TARGET} MATCHES "~$")
        string(REGEX REPLACE "~$" "_tilde" OBJ_TARGET ${OBJ_TARGET})
    endif()

    foreach(DATA_FILE ${DATA_FILE})

        # INSTALL (install-time)
        if(PD_DATAFILE_DESTINATION)
            set(_DEST "${PDLIBDIR}/${PROJECT_NAME}/${PD_DATAFILE_DESTINATION}")
        else()
            set(_DEST "${PDLIBDIR}/${PROJECT_NAME}")
        endif()

        if(IS_DIRECTORY "${DATA_FILE}")
            install(DIRECTORY "${DATA_FILE}" DESTINATION "${_DEST}")
        else()
            install(FILES "${DATA_FILE}" DESTINATION "${_DEST}")
        endif()

        # BUILD-TIME COPY
        if(PD_OUTPUT_PATH)

            # Ensure output directory exists
            add_custom_command(
                TARGET ${OBJ_TARGET}
                POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory "${PD_OUTPUT_PATH}")

            if(IS_DIRECTORY "${DATA_FILE}")
                add_custom_command(
                    TARGET ${OBJ_TARGET}
                    POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_directory "${DATA_FILE}" "${PD_OUTPUT_PATH}")
            else()
                add_custom_command(
                    TARGET ${OBJ_TARGET}
                    POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DATA_FILE}"
                            "${PD_OUTPUT_PATH}/")
            endif()
        endif()

    endforeach()
endfunction()

# ──────────────────────────────────────
macro(pd_set_lib_ext OBJ_TARGET_NAME)
    if(EMSCRIPTEN)
        return()
    endif()

    if(NOT PD_EXTENSION)
        message(
            FATAL_ERROR
                "Not possible to determine the extension of the library, please set PD_EXTENSION")
    endif()

    strip_trailing_dot(pdx "${PD_EXTENSION}")
    set_target_properties(${OBJ_TARGET_NAME} PROPERTIES SUFFIX ".${pdx}")
endmacro(pd_set_lib_ext)

# ──────────────────────────────────────
function(pd_add_external PD_EXTERNAL_NAME EXTERNAL_SOURCES)

    set(BOOLEAN_ARGS) # No args for now
    set(ONE_ARGS TARGET EXTERNAL_NAME) # Define optional arg for TARGET
    set(MULTI_ARGS CXX_FLAGS C_FLAGS LINK_LIBRARIES) # Define multi args, CXX_FLAGS C_FLAGS
    cmake_parse_arguments(PD_EXTERNAL "${BOOLEAN_ARGS}" "${ONE_ARGS}" "${MULTI_ARGS}" ${ARGN})

    # Warning case external name contains ~ and TARGET IS NOT DEFINED
    if(${PD_EXTERNAL_NAME} MATCHES "~$" AND "${PD_EXTERNAL_TARGET}" STREQUAL "")
        string(REGEX REPLACE "~$" "_tilde" OBJ_TARGET_NAME ${PD_EXTERNAL_NAME})
        if(${ENABLE_TILDE_TARGET_WARNING})
            message(WARNING "TARGET for the external ${PD_EXTERNAL_NAME} contains \"~\", "
                            "replacing with _tilde. Use TARGET keyword in pd_add_external "
                            "to define a custom target name.\n")
        endif()
    elseif(NOT ${PD_EXTERNAL_TARGET} STREQUAL "")
        set(OBJ_TARGET_NAME ${PD_EXTERNAL_TARGET})
    else()
        set(OBJ_TARGET_NAME ${PD_EXTERNAL_NAME})
    endif()

    if(DEFINED PD_EXTERNAL_EXTERNAL_NAME)
        set(PD_EXTERNAL_NAME "${PD_EXTERNAL_EXTERNAL_NAME}")
    endif()

    if(EMSCRIPTEN OR PD_BUILD_STATIC_OBJECTS)
        add_library(${OBJ_TARGET_NAME} STATIC ${EXTERNAL_SOURCES})
        set_target_properties(${OBJ_TARGET_NAME} PROPERTIES OUTPUT_NAME ${PD_EXTERNAL_NAME})
        set_property(GLOBAL APPEND PROPERTY ${PROJECT_NAME}_STATIC_LIBRARIES ${OBJ_TARGET_NAME})
    else()
        add_library(${OBJ_TARGET_NAME} SHARED ${EXTERNAL_SOURCES})
        set_target_properties(${OBJ_TARGET_NAME} PROPERTIES PREFIX "")
        set_target_properties(${OBJ_TARGET_NAME} PROPERTIES OUTPUT_NAME ${PD_EXTERNAL_NAME})
        pd_set_lib_ext(${OBJ_TARGET_NAME})
        get_property(
            PD_EXTENSION
            TARGET ${OBJ_TARGET_NAME}
            PROPERTY SUFFIX)
    endif()

    if(PD_OUTPUT_PATH)
        set_target_properties(
            ${OBJ_TARGET_NAME}
            PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${PD_OUTPUT_PATH}"
                       ARCHIVE_OUTPUT_DIRECTORY "${PD_OUTPUT_PATH}"
                       RUNTIME_OUTPUT_DIRECTORY "${PD_OUTPUT_PATH}")
    else()
        set_target_properties(${OBJ_TARGET_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY
                                                            ${CMAKE_CURRENT_BINARY_DIR})
        set_target_properties(${OBJ_TARGET_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY
                                                            ${CMAKE_CURRENT_BINARY_DIR})
        set_target_properties(${OBJ_TARGET_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY
                                                            ${CMAKE_CURRENT_BINARY_DIR})
    endif()

    # Check if CXX_FLAGS is defined, if true set the flags
    if(DEFINED PD_EXTERNAL_CXX_FLAGS)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PD_EXTERNAL_CXX_FLAGS}")
    endif()

    # Check if C_FLAGS is defined, if true set the flags
    if(DEFINED PD_EXTERNAL_C_FLAGS)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${PD_EXTERNAL_C_FLAGS}")
    endif()

    # Check if LINK_LIBRARIES is defined, if true set the flags
    if(DEFINED PD_EXTERNAL_LINK_LIBRARIES)
        target_link_libraries(${OBJ_TARGET_NAME} PUBLIC ${PD_EXTERNAL_LINK_LIBRARIES})
    endif()
    target_include_directories(${OBJ_TARGET_NAME} PUBLIC ${PD_SOURCES_PATH}) # Add Pd Includes

    # fix this
    if(WIN32)
        if(MSVC)
            if(PD_FLOATSIZE EQUAL 64)
                target_link_libraries(${OBJ_TARGET_NAME} PUBLIC "${PDBINDIR}/pd64.lib")
            else()
                target_link_libraries(${OBJ_TARGET_NAME} PUBLIC "${PDBINDIR}/pd.lib")
            endif()
        elseif(MINGW)
            if(PD_FLOATSIZE EQUAL 64)
                target_link_options(${OBJ_TARGET_NAME} PUBLIC "-Wl,--enable-auto-import")
                target_link_libraries(${OBJ_TARGET_NAME} PUBLIC "${PDBINDIR}/pd64.dll")
            else()
                target_link_options(${OBJ_TARGET_NAME} PUBLIC "-Wl,--enable-auto-import")
                target_link_libraries(${OBJ_TARGET_NAME} PUBLIC "${PDBINDIR}/pd.dll")
            endif()
        endif()
    elseif(APPLE)
        set_target_properties(${OBJ_TARGET_NAME} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
    endif()

    if(NOT PD_FLOATSIZE EQUAL 32)
        target_compile_definitions(${OBJ_TARGET_NAME} PUBLIC PD_FLOATSIZE=${PD_FLOATSIZE})
    endif()

    strip_trailing_dot(pdx "${PD_EXTENSION}")
    if(NOT PD_BUILD_STATIC_OBJECTS)
        if (PD_OUTPUT_PATH)
            install(TARGETS ${OBJ_TARGET_NAME} DESTINATION "${PD_OUTPUT_PATH}")
        else()  
            install(TARGETS ${OBJ_TARGET_NAME} DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
        endif()
    endif()

    if(MSVC)
        string(FIND ${PD_EXTERNAL_NAME} "." NAME_HAS_DOT)
        string(FIND ${PD_EXTERNAL_NAME} "~" NAME_HAS_TILDE)
        if(NAME_HAS_DOT EQUAL -1)
            string(REPLACE "~" "_tilde" EXPORT_FUNCTION "${PD_EXTERNAL_NAME}_setup")
        else()
            string(REPLACE "." "0x2e" TEMP_NAME "${PD_EXTERNAL_NAME}")
            string(REPLACE "~" "_tilde" EXPORT_FUNCTION "setup_${TEMP_NAME}")
        endif()
        set_property(
            TARGET ${OBJ_TARGET_NAME}
            APPEND_STRING
            PROPERTY LINK_FLAGS "/export:${EXPORT_FUNCTION}")
    endif()

endfunction(pd_add_external)

# ──────────────────────────────────────
function(add_pd_external PROJECT_NAME EXTERNAL_NAME EXTERNAL_SOURCES)
    message(WARNING "add_pd_external is deprecated, use pd_add_external instead.\n")

    set(ALL_SOURCES ${EXTERNAL_SOURCES})
    list(APPEND ALL_SOURCES ${ARGN})
    source_group(src FILES ${ALL_SOURCES})
    add_library(${PROJECT_NAME} SHARED ${ALL_SOURCES})
    set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")
    set_property(TARGET ${PROJECT_NAME} PROPERTY EXTERNAL_DATA_FILES "")

    target_include_directories(${PROJECT_NAME} PUBLIC ${PD_SOURCES_PATH})
    set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME ${EXTERNAL_NAME})

    # Defines the output path of the external.
    set_target_properties(${PROJECT_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
    set_target_properties(${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
    set_target_properties(${PROJECT_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

    foreach(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
        string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG)
        set_target_properties(${PROJECT_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG}
                                                         ${CMAKE_BINARY_DIR})
        set_target_properties(${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG}
                                                         ${CMAKE_BINARY_DIR})
        set_target_properties(${PROJECT_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG}
                                                         ${CMAKE_BINARY_DIR})
    endforeach(OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES)

    if(WIN32)
        if(PD_FLOATSIZE EQUAL 64)
            target_link_libraries(${PROJECT_NAME} PUBLIC "${PDBINDIR}/pd64.lib")
        elseif(PD_FLOATSIZE EQUAL 32)
            target_link_libraries(${PROJECT_NAME} PUBLIC "${PDBINDIR}/pd.lib")
        endif()
    elseif(APPLE)
        set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
    endif()

    get_property(
        PD_EXTENSION
        TARGET ${PROJECT_NAME}
        PROPERTY SUFFIX) # set extension

    if(PD_FLOATSIZE STREQUAL 64)
        target_compile_definitions(${PROJECT_NAME} PUBLIC PD_FLOATSIZE=64)
    endif()

    pd_set_lib_ext(${PROJECT_NAME})
    strip_trailing_dot(pdx "${PD_EXTENSION}")
    pd_add_datafile(${PROJECT_NAME} "${CMAKE_CURRENT_BINARY_DIR}/${PD_EXTERNAL_NAME}.${pdx}")

endfunction(add_pd_external)

function(calc_pd_extension)
    if(EMSCRIPTEN)
        # no extension required for emscripten
        return()
    endif()

    if(PD_EXTENSION)
        # already got an extension...
        return()
    endif()

    # no extension given, calculate a generic one: .<os>-<cpu>-<floatsize>.<ext>

    # the extension suffix is '.dll' on Windows and '.so' on un*x (aka: everything else)
    if(WIN32)
        set(ext "dll")
    else()
        set(ext "so")
    endif()

    # use the lowercase system_name for the <os>
    string(TOLOWER "${CMAKE_SYSTEM_NAME}" os)
    # normalize names
    if(os STREQUAL "msys")
        set(os "windows")
    elseif(os STREQUAL "mingw")
        set(os "windows")
    endif()
    if(os STREQUAL "")
        message(FATAL_ERROR "Not possible to determine OS name, please set CMAKE_SYSTEM_NAME")
    endif()
    message(STATUS "Detected '${os}' for system name '${CMAKE_SYSTEM_NAME}'")

    if(APPLE AND (CMAKE_OSX_ARCHITECTURES STREQUAL ""))
        # get rid of this: people should actively set CMAKE_OSX_ARCHITECTURES to their desired archs
        # cf the [docs](https://cmake.org/cmake/help/latest/variable/CMAKE_OSX_ARCHITECTURES.html):
        # > The value of this variable should be set prior to the first project() [...]. > It is
        # intended to be set locally by the user creating a build tree.
        set(CMAKE_OSX_ARCHITECTURES
            "x86_64;arm64"
            CACHE STRING "Target architectures" FORCE)
    endif()

    # use the lowercase processor for the <cpu>
    string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" cpu)

    # OS specific overrides
    if(APPLE AND (NOT CMAKE_OSX_ARCHITECTURES STREQUAL ""))
        if(CMAKE_OSX_ARCHITECTURES MATCHES ".*;.*")
            set(cpu "fat")
            message(STATUS "Apple universal compilation")
        else()
            set(cpu ${CMAKE_OSX_ARCHITECTURES})
            message(STATUS "Apple ${cpu} compilation")
        endif()
    elseif(WIN32 AND (cpu MATCHES "(x86_64|amd64)"))
        if(CMAKE_SIZEOF_VOID_P EQUAL 4)
            # urgh. this shouldn't be needed
            message(
                WARNING
                    "Detected CPU ${CMAKE_SYSTEM_PROCESSOR} with a ${CMAKE_SIZEOF_VOID_P}byte pointer...fixing"
            )
            set(cpu "i386")
        endif()
    endif()

    # normalize some names
    if(cpu STREQUAL "x86_64")
        set(cpu "amd64")
    elseif(cpu MATCHES "i[0-9]86")
        set(cpu "i386")
    elseif(cpu STREQUAL "aarch64")
        set(cpu "arm64")
    elseif(cpu MATCHES "arm.*")
        set(cpu "arm")
    endif()

    if(cpu STREQUAL "")
        message(FATAL_ERROR "Not possible to determine CPU name, please set CMAKE_SYSTEM_PROCESSOR")
    endif()
    message(STATUS "Detected '${cpu}' for system CPU '${CMAKE_SYSTEM_PROCESSOR}'")

    set(PD_EXTENSION
        "${os}-${cpu}-${PD_FLOATSIZE}.${ext}"
        PARENT_SCOPE)
endfunction()

function(strip_trailing_dot var input)
    string(REGEX REPLACE "^\\.(.*)$" "\\1" tmp "${input}")
    set(${var}
        "${tmp}"
        PARENT_SCOPE)
endfunction()

# ╭──────────────────────────────────────╮
# │        Set pd.cmake variables        │
# ╰──────────────────────────────────────╯
set(PDCMAKE_DIR
    ${CMAKE_CURRENT_LIST_DIR}
    CACHE STRING "PATH where is located pd.cmake file")

set(PD_FLOATSIZE
    32
    CACHE STRING "the floatsize of Pd (32 or 64)")
set_property(CACHE PD_FLOATSIZE PROPERTY STRINGS 32 64)
if(NOT (PD_FLOATSIZE EQUAL 64 OR PD_FLOATSIZE EQUAL 32))
    message(FATAL_ERROR "PD_FLOATSIZE must be 32 or 64")
endif()

calc_pd_extension()
set(PD_EXTENSION
    "${PD_EXTENSION}"
    CACHE STRING "Pd extension (e.g. 'pd_linux')")

set(PD_SOURCES_PATH
    ""
    CACHE PATH "Path to Pd sources")

set(PD_ENABLE_TILDE_TARGET_WARNING
    ON
    CACHE BOOL "Warning for Target with tilde")

set(PD_INSTALL_LIBS
    ON
    CACHE BOOL "Install Pd Externals on PDLIBDIR")

set(PD_BUILD_STATIC_OBJECTS
    OFF
    CACHE
        BOOL
        "Enable building static objects. Useful when using self-contained objects with libpd, such as in embedded systems or standalone applications."
)

# ╭──────────────────────────────────────╮
# │         Get default PDLIBDIR         │
# ╰──────────────────────────────────────╯
if(APPLE)
    set(PDLIBDIR
        "~/Library/Pd"
        CACHE PATH "Path where lib will be installed")
elseif(UNIX)
    set(PDLIBDIR
        "/usr/local/lib/pd-externals"
        CACHE PATH "Path where lib will be installed")
elseif(WIN32)
    set(PDLIBDIR
        "$ENV{APPDATA}/Pd"
        CACHE PATH "Path where lib will be installed")
else()
    message(FATAL_ERROR "Platform not supported")
endif()

if(PD_INSTALL_LIBS)
    message(STATUS "Pd Install Libs Path: ${PDLIBDIR}")
endif()

# ╭──────────────────────────────────────╮
# │   ToolChain for Raspberry (others)   │
# ╰──────────────────────────────────────╯
if(NOT PD_SOURCES_PATH)
    if(WIN32 OR MINGW)
        if(PD_FLOATSIZE EQUAL 64)
            set(PD_SOURCES_PATH "C:/Program Files/Pd64/src")
            if(NOT PDBINDIR)
                set(PDBINDIR "C:/Program Files/Pd64/bin")
            endif()
        elseif(PD_FLOATSIZE EQUAL 32)
            set(PD_SOURCES_PATH "C:/Program Files/Pd/src")
            if(NOT PDBINDIR)
                set(PDBINDIR "C:/Program Files/Pd/bin")
            endif()
        endif()
        find_library(
            PD_LIBRARY
            NAMES pd
            HINTS ${PDBINDIR})
        find_path(PD_HEADER_PATH m_pd.h PATHS ${PD_SOURCES_PATH})
        if(NOT PD_HEADER_PATH)
            message(
                FATAL_ERROR "<m_pd.h> not found in C:\\Program Files\\Pd\\src, is Pd installed?")
        endif()

    elseif(APPLE)
        file(GLOB PD_INSTALLER "/Applications/Pd*.app")
        if(PD_INSTALLER)
            foreach(app ${PD_INSTALLER})
                get_filename_component(PD_SOURCES_PATH "${app}/Contents/Resources/src/" ABSOLUTE)
            endforeach()
        else()
            message(
                FATAL_ERROR
                    "PD_SOURCES_PATH not set and no Pd.app found in /Applications, is Pd installed?"
            )
        endif()

        find_path(PD_HEADER_PATH m_pd.h PATHS ${PD_SOURCES_PATH})
        if(NOT PD_HEADER_PATH)
            message(
                FATAL_ERROR
                    "<m_pd.h> not found in /Applications/Pd.app/Contents/Resources/src/, is Pd installed?"
            )
        endif()
        message(STATUS "PD_SOURCES_PATH not set, using ${PD_SOURCES_PATH}")

    elseif(UNIX AND NOT APPLE)
        if(NOT PD_SOURCES_PATH)
            set(PD_SOURCES_PATH "/usr/include/pd/")
            if(NOT EXISTS "${PD_SOURCES_PATH}")
                set(PD_SOURCES_PATH "/usr/local/include/pd")
            endif()
        endif()
        if(NOT PDBINDIR)
            set(PDBINDIR ${PD_SOURCES_PATH}/../bin)
        endif()
        find_path(PD_HEADER_PATH m_pd.h PATHS ${PD_SOURCES_PATH})
        if(NOT PD_HEADER_PATH AND NOT EMSCRIPTEN)
            message(WARNING "<m_pd.h> not found in /usr/include/pd/, is Pd installed?")
        endif()

    else()
        message(FATAL_ERROR "PD_SOURCES_PATH not set and no default path for the system")
    endif()
    set(PD_SOURCES_PATH ${PD_SOURCES_PATH})
endif()
