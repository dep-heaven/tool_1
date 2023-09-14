cmake_minimum_required(VERSION 3.16)
project(tool_1 VERSION 1.0.0 LANGUAGES CXX)

# ###############################################################################
# Dependencies via list in file

# include(FetchContent)

# FetchContent_Declare(
# cmake_utilities
# GIT_REPOSITORY https://github.com/daixtrose/cmake_utilities
# GIT_TAG        main
# )

# FetchContent_MakeAvailable(cmake_utilities)

# fetchcontent_dependencies(
# FILENAME dependencies.txt
# WORKSPACE ws)
include(FetchContent)

FetchContent_Declare(
    cmake_utilities
    GIT_REPOSITORY https://github.com/daixtrose/cmake_utilities
    GIT_TAG main
)

# Use a workspace instead of the default FetchContent directories
set(REPOMAN_DEPENDENCIES_USE_WORKSPACE ON CACHE BOOL "")

# Optional: set a custom name and/or location for the workspace
# set(REPOMAN_DEPENDENCIES_WORKSPACE "../" CACHE PATH "") # use automatically generated directory name next to current project
# set(REPOMAN_DEPENDENCIES_WORKSPACE "../my_ws" CACHE PATH "") # use custom directory name next to current project
# set(REPOMAN_DEPENDENCIES_WORKSPACE "my_ws" CACHE PATH "") # use custom name inside current project build directory
set(REPOMAN_DEPENDENCIES_WORKSPACE "ws" CACHE PATH "") # use absolute path

# Use a custom file name for dependency files
set(REPOMAN_DEPENDENCIES_FILE_NAME "dependencies.txt" CACHE STRING "")

FetchContent_MakeAvailable(cmake_utilities)

list(APPEND CMAKE_MODULE_PATH ${cmake_utilities_SOURCE_DIR}/experiments)
include(CompilerFlags)

# ###############################################################################
# the tool
add_executable(${PROJECT_NAME}
    src/fn.cpp
    src/tool_1.cpp)

# Some experiment   
# TODO: fix it 
# include(experiments/CompilerFlags)
# apply_rpath_settings(${PROJECT_NAME})

target_include_directories(
    ${PROJECT_NAME} PUBLIC
    include
)

target_link_libraries(
    ${PROJECT_NAME}
    PUBLIC
    Daixtrose::lib_A
    lib_B
    $<BUILD_INTERFACE:Daixtrose::CxxFlags>
    fmt::fmt
)

message("WARNING! Something is still wrong here!")
FetchContent_GetProperties("catch2")
message("   RepoMan should populate selected name, not original name")
message("==> Toplevel: catch2_SOURCE_DIR = '${catch2_SOURCE_DIR}'")
message("==> Toplevel: Catch2_SOURCE_DIR = '${Catch2_SOURCE_DIR}'")
FetchContent_GetProperties("lib_A")
message("==> Toplevel: lib_a_SOURCE_DIR = '${lib_a_SOURCE_DIR}'")
message("==> Toplevel: lib_A_SOURCE_DIR = '${lib_A_SOURCE_DIR}'")

if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
    enable_testing()
    add_subdirectory(test-catch)
endif()

# Packaging omitted
