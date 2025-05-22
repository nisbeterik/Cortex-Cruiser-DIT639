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

project(performance)

# Add the common library - with flexible path detection
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/../common)
    # Local environment with relative paths
    set(COMMON_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../common)
    add_subdirectory(${COMMON_DIR} ${CMAKE_BINARY_DIR}/common)
elseif(EXISTS /opt/sources/common)
    # Docker environment
    set(COMMON_DIR /opt/sources/common)
    add_subdirectory(${COMMON_DIR} ${CMAKE_BINARY_DIR}/common)
else()
    message(FATAL_ERROR "Cannot find common directory!")
endif()

# Set the search path for .cmake files
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}" ${CMAKE_MODULE_PATH})

# C++ standard and flags
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++")

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

# Threads
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

# Code coverage
option(CODE_COVERAGE "Enable coverage reporting" OFF)
if(CODE_COVERAGE)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        message(STATUS "Code coverage enabled")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage -O0")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
    endif()
endif()

# Includes
include_directories(SYSTEM ${CMAKE_BINARY_DIR})  # For generated headers
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
include_directories(${COMMON_DIR}/include)

# Libraries
set(LIBRARIES Threads::Threads)

if(UNIX AND NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    find_package(LibRT REQUIRED)
    set(LIBRARIES ${LIBRARIES} ${LIBRT_LIBRARIES})
    include_directories(SYSTEM ${LIBRT_INCLUDE_DIR})
endif()

# OpenCV
find_package(OpenCV REQUIRED core highgui imgproc)
include_directories(SYSTEM ${OpenCV_INCLUDE_DIRS})
set(LIBRARIES ${LIBRARIES} ${OpenCV_LIBS})

# Additional libraries
set(LIBRARIES ${LIBRARIES} yuv openh264)
include_directories(SYSTEM /usr/include)

# Create executable
add_executable(${PROJECT_NAME} src/${PROJECT_NAME}.cpp)

# Dependencies
add_dependencies(${PROJECT_NAME} generate-opendlv-header generate-cluon-msc)

target_link_libraries(${PROJECT_NAME} 
    ${LIBRARIES}
    steering_common
)

# Install
add_definitions(-DREC_PROCESSING)
install(TARGETS ${PROJECT_NAME} DESTINATION bin COMPONENT ${PROJECT_NAME})