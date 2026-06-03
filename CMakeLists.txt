cmake_minimum_required(VERSION 3.15)
project(DIGICRON LANGUAGES C CXX)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/build)

file(GLOB EPOXY_SOURCES
    ${CMAKE_SOURCE_DIR}/devdeps/EpoxyDuino/cores/epoxy/*.cpp
    ${CMAKE_SOURCE_DIR}/devdeps/EpoxyDuino/cores/epoxy/*.h
)

file(GLOB VREMU6502_SOURCES
    ${CMAKE_SOURCE_DIR}/lib/vrEmu6502/src/*.c
    ${CMAKE_SOURCE_DIR}/lib/vrEmu6502/src/*.h
)

add_library(EpoxyDuino STATIC ${EPOXY_SOURCES})
add_library(VrEmu6502 STATIC ${VREMU6502_SOURCES})

set_target_properties(VrEmu6502 PROPERTIES LINKER_LANGUAGE C)

target_include_directories(EpoxyDuino PUBLIC ${CMAKE_SOURCE_DIR}/devdeps/EpoxyDuino/cores/epoxy)
target_include_directories(VrEmu6502 PUBLIC ${CMAKE_SOURCE_DIR}/lib/vrEmu6502/src)

file(GLOB SOURCES
    ${CMAKE_SOURCE_DIR}/firmware/*.cpp
)

add_executable(digicron ${SOURCES})

add_definitions(
    -DDC_SIMULATOR
)

set_target_properties(digicron PROPERTIES LINK_FLAGS "--bind")

target_include_directories(digicron PRIVATE ${CMAKE_SOURCE_DIR}/devdeps/EpoxyDuino/cores/epoxy)

target_link_libraries(digicron PRIVATE EpoxyDuino VrEmu6502)