cmake_minimum_required(VERSION 2.8.12)

# Set extension name here
set(TARGET_NAME faiss)

set(EXTENSION_NAME ${TARGET_NAME}_extension)
project(${TARGET_NAME})
include_directories(src/include)

# we don't need other peoples build script
file(
        GLOB
        EXTENSION_SOURCES
        src/*.cpp
        "faiss/faiss/*.cpp"
        "faiss/faiss/impl/*.cpp"
        "faiss/faiss/invlists/*.cpp"
        "faiss/faiss/utils/*.cpp"
        "faiss/faiss/utils/distances_fused/*.cpp")
add_definitions(-DFINTEGER=int)

add_library(${EXTENSION_NAME} STATIC ${EXTENSION_SOURCES})
include_directories(faiss/ libomp/omp/build/runtime/src)

# yay cmake this needs to be an absolute path
set(OMP_STATIC_LIB ${CMAKE_CURRENT_SOURCE_DIR}/libomp/omp/build/runtime/src/libomp.a)

add_custom_command(
        OUTPUT ${OMP_STATIC_LIB}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMAND sh ompconfigure)

if(APPLE)
  target_link_libraries(${EXTENSION_NAME} "-framework Accelerate")
endif()

add_custom_target(BuildOMP DEPENDS ${OMP_STATIC_LIB})
add_dependencies(${EXTENSION_NAME} BuildOMP)

target_link_libraries(${EXTENSION_NAME} ${OMP_STATIC_LIB})

set(EXTENSION_SOURCES ${EXTENSION_SOURCES} ${FAISS_SOURCES})

set(PARAMETERS "-warnings")
build_loadable_extension(${TARGET_NAME} ${PARAMETERS} ${EXTENSION_SOURCES})

install(
        TARGETS ${EXTENSION_NAME}
        EXPORT "${DUCKDB_EXPORT_SET}"
        LIBRARY DESTINATION "${INSTALL_LIB_DIR}"
        ARCHIVE DESTINATION "${INSTALL_LIB_DIR}")