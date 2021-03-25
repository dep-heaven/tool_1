cmake_minimum_required(VERSION 3.16)
project(tool_1 VERSION 1.0.0 LANGUAGES CXX)

################################################################################
# Dependencies via list in file

include(FetchContent)

FetchContent_Declare(
  cmake_utilities
  GIT_REPOSITORY https://github.com/daixtrose/cmake_utilities
  GIT_TAG        main
)

FetchContent_MakeAvailable(cmake_utilities)

fetchcontent_dependencies(
    FILENAME dependencies.txt 
    WORKSPACE ws)


################################################################################
# the tool

add_executable(${PROJECT_NAME}
    src/fn.cpp
    src/tool_1.cpp)

apply_rpath_settings(${PROJECT_NAME})    

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

if (CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME) 
    enable_testing()
    add_subdirectory(test-catch)
endif()

# Packaging omitted  