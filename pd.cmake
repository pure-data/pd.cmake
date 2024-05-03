set(PD_CMAKE_PATH ${CMAKE_CURRENT_LIST_DIR})
set(PD_OUTPUT_PATH)

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
function(get_pd_lib_path)
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
endfunction(get_pd_lib_path)

# ──────────────────────────────────────
function(get_pd_lib_ext)
    if(PD_EXTENSION)
        set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".${PD_EXTENSION}")
    else()
        if(APPLE)
            if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
                set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".d_arm64")
            else()
                set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".d_amd64")
            endif()
            set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
        elseif(UNIX)
            if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
                set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".l_arm")
            else()
                set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".l_amd64")
            endif()
        elseif(WIN32)
            set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".m_amd64")
        endif()
    endif()
endfunction(get_pd_lib_ext)

# ──────────────────────────────────────
function(add_pd_external PROJECT_NAME EXTERNAL_NAME EXTERNAL_SOURCES)
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

    get_pd_lib_path()
    get_pd_lib_ext()

    # TODO: Add MSVC support
endfunction(add_pd_external)

