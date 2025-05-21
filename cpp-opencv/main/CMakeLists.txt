# Copyright (C) 2020  Christian Berger
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

cmake_minimum_required(VERSION 3.2)

project(main)

# Add the common library - with flexible path detection
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/../common)
    # GitLab CI/CD environment or local environment with relative paths
    set(COMMON_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../common)
    add_subdirectory(${COMMON_DIR} ${CMAKE_BINARY_DIR}/common)
elseif(EXISTS /opt/sources/common)
    # Docker environment 
    set(COMMON_DIR /opt/sources/common)
    add_subdirectory(${COMMON_DIR} ${CMAKE_BINARY_DIR}/common)
else()
    message(FATAL_ERROR "Cannot find common directory! Checked ${CMAKE_CURRENT_SOURCE_DIR}/../common and /opt/sources/common")
endif()

################################################################################
# Set the search path for .cmake files.
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}" ${CMAKE_MODULE_PATH})

################################################################################
# This project requires C++14 or newer.
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
# Build a static binary.
set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++")
# Add further warning levels to increase the code quality.
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} \
    -D_XOPEN_SOURCE=700 \
    -D_FORTIFY_SOURCE=2 \
    -O2 \
    -fstack-protector \
    -fomit-frame-pointer \
    -pipe \
    -Weffc++ \
    -Wall -Wextra -Wshadow -Wdeprecated \
    -Wdiv-by-zero -Wfloat-equal -Wfloat-conversion -Wsign-compare -Wpointer-arith \
    -Wuninitialized -Wunreachable-code \
    -Wunused -Wunused-function -Wunused-label -Wunused-parameter -Wunused-but-set-parameter -Wunused-but-set-variable \
    -Wunused-value -Wunused-variable -Wunused-result \
    -Wmissing-field-initializers -Wmissing-format-attribute -Wmissing-include-dirs -Wmissing-noreturn")

# Threads are necessary for linking the resulting binaries as the network communication is running inside a thread.
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

option(CODE_COVERAGE "Enable coverage reporting" OFF)

if(CODE_COVERAGE)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        message(STATUS "Code coverage enabled")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage -O0")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
    endif()
else()
    set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++")
endif()

# Includes
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
include_directories(${COMMON_DIR}/include)

################################################################################
# Gather all object code first to avoid double compilation.
set(LIBRARIES Threads::Threads)

if(UNIX)
    if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
        find_package(LibRT REQUIRED)
        set(LIBRARIES ${LIBRARIES} ${LIBRT_LIBRARIES})
        include_directories(SYSTEM ${LIBRT_INCLUDE_DIR})
    endif()
endif()

# This project uses OpenCV for image processing.
find_package(OpenCV REQUIRED core highgui imgproc)
include_directories(SYSTEM ${OpenCV_INCLUDE_DIRS})
include_directories(SYSTEM ${CMAKE_BINARY_DIR})
set(LIBRARIES ${LIBRARIES} ${OpenCV_LIBS})

################################################################################
# Create executable
add_executable(${PROJECT_NAME} src/${PROJECT_NAME}.cpp)

# Add dependency to OpenDLV Standard Message Set.
add_dependencies(${PROJECT_NAME} generate-opendlv-header)
add_dependencies(${PROJECT_NAME} generate-cluon-msc)

target_link_libraries(${PROJECT_NAME} 
    ${LIBRARIES}
    steering_common
)

# Install executable
install(TARGETS ${PROJECT_NAME} DESTINATION bin COMPONENT ${PROJECT_NAME})

# Test executable
add_executable(${PROJECT_NAME}-Runner src/test-template.cpp src/istrue.cpp)

add_dependencies(${PROJECT_NAME}-Runner generate-opendlv-header)

target_link_libraries(${PROJECT_NAME}-Runner 
    ${LIBRARIES}
    steering_common
)

enable_testing()
add_test(NAME ${PROJECT_NAME}-Runner COMMAND ${PROJECT_NAME}-Runner)