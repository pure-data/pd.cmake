
# The path to this file.
set(PD_CMAKE_PATH ${CMAKE_CURRENT_LIST_DIR})
# The path to Pure Data sources.
#set(PD_SOURCES_PATH)
# The output path for the externals.
set(PD_OUTPUT_PATH)
if(WIN32)
	if(NOT PD_LIB_PATH)
		if("${CMAKE_GENERATOR}" MATCHES "(Win64|IA64)" OR "${CMAKE_GENERATOR_PLATFORM}" MATCHES "x64" OR "$ENV{VSCMD_ARG_TGT_ARCH}" MATCHES "x64")
			set(PD_LIB_PATH  ${PD_CMAKE_PATH}/x64)
		else()
			set(PD_LIB_PATH  ${PD_CMAKE_PATH}/x86)
		endif()
	endif()
endif()

if(${APPLE})
	# For Libraries installed using brew
	include_directories(/usr/local/include)
	link_directories(/usr/local/lib)
	if(NOT PD_SOURCE_PATH)
		file(GLOB PD_INSTALLER "/Applications/Pd*.app")
		if(PD_INSTALLER)
			foreach(app ${PD_INSTALLER})
				get_filename_component(PD_SOURCE_PATH "${app}/Contents/Resources/src/" ABSOLUTE)
			endforeach()
		else()
			message(FATAL_ERROR "PD_SOURCE_PATH not set and no Pd.app found in /Applications")
		endif()
		message(STATUS "PD_SOURCE_PATH not set, using ${PD_SOURCE_PATH}")
		set (PD_SOURCES_PATH ${PD_SOURCE_PATH})
	endif()
endif()
# The function adds an external to the project.
# PROJECT_NAME is the name of your project (for example: freeverb_project)
# EXTERNAL_NAME is the name of your external (for example: freeverb~)
# EXTERNAL_SOURCES are the source files (for example: freeverb~.c)
# The function should be call:
# add_external(freeverb_project freeverb~ userpath/freeverb~.c userpath/otherfile.c)
# later see how to manage relative and absolute path
function(add_pd_external PROJECT_NAME EXTERNAL_NAME EXTERNAL_SOURCES)

    set(ALL_SOURCES ${EXTERNAL_SOURCES}) 
    list(APPEND ALL_SOURCES ${ARGN})

    source_group(src FILES ${ALL_SOURCES})
    add_library(${PROJECT_NAME} SHARED ${ALL_SOURCES})

	# Defines plateform specifix suffix and the linking necessities.
	set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")
	target_include_directories(${PROJECT_NAME} PRIVATE ${PD_SOURCES_PATH})

	if(${APPLE})
		# Pd external extensions
        if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
            set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".d_arm64")
        else()
            set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".d_amd64")
        endif()

		set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")


	elseif(${UNIX})
        if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
            if (CMAKE_SIZEOF_VOID_P EQUAL 8)
                set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".l_amd64")
            else()
                set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".l_arm")
            endif()
        else()
            set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".l_amd64")
        endif()
	elseif(${WIN32})
        # SOMEONE USES THE 32 BITS VERSION OF PD ON WINDOWS?
		set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".m_amd64")
		find_library(PD_LIBRARY NAMES pd HINTS ${PD_LIB_PATH})
		target_link_libraries(${PROJECT_NAME} ${PD_LIBRARY})
	endif()

	# Removes some warning for Microsoft Visual C.
	if(${MSVC})
		set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY COMPILE_FLAGS "/wd4091 /wd4996")
	endif()

	# Adds
	if(WIN32)
		if(${CMAKE_SIZEOF_VOID_P} EQUAL 8)
			set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY COMPILE_FLAGS " /DPD_LONGINTTYPE=\"long long\"")
		endif()
	endif()

	# Support for PD double precision
	if(PD_FLOATSIZE64)
		set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY COMPILE_FLAGS " -DPD_FLOATSIZE=64")
	endif()

	# Includes the path to Pure Data sources.

	# Defines the name of the external.
	# On XCode with CMake < 3.4 if the name of an external ends with tilde but doesn't have a dot, the name must be 'name~'.
	# CMake 3.4 is not sure, but it should be between 3.3.2 and 3.6.2
	string(FIND ${EXTERNAL_NAME} "." NAME_HAS_DOT)
	string(FIND ${EXTERNAL_NAME} "~" NAME_HAS_TILDE)
	if((${CMAKE_VERSION} VERSION_LESS 3.4) AND (CMAKE_GENERATOR STREQUAL Xcode) AND (NAME_HAS_DOT EQUAL -1) AND (NAME_HAS_TILDE GREATER -1))
		set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME '${EXTERNAL_NAME}')
	else()
		set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME ${EXTERNAL_NAME})
	endif()

	# Generate the function to export for Windows
	if(${WIN32})
		if(NAME_HAS_DOT EQUAL -1)
			string(REPLACE "~" "_tilde" EXPORT_FUNCTION "${EXTERNAL_NAME}_setup")
		else()
			string(REPLACE "." "0x2e" TEMP_NAME "${EXTERNAL_NAME}")
			string(REPLACE "~" "_tilde" EXPORT_FUNCTION "setup_${TEMP_NAME}")
		endif()
		set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY LINK_FLAGS "/export:${EXPORT_FUNCTION}")
	endif()

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

endfunction(add_pd_external)

# The macro defines the output path of the externals.
macro(set_pd_external_path EXTERNAL_PATH)
	set(PD_OUTPUT_PATH ${EXTERNAL_PATH})
endmacro(set_pd_external_path)

# The macro sets the location of Pure Data sources.
macro(set_pd_sources PD_SOURCES)
	set(PD_SOURCES_PATH ${PD_SOURCES})
endmacro(set_pd_sources)
