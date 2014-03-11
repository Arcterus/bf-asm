cmake_minimum_required (VERSION 2.8)
project (ftb)

enable_language (ASM_NASM)

set (CMAKE_ASM_NASM_LINK_EXECUTABLE "ld -e _start -o <TARGET> <OBJECTS>")

file (GLOB ASM_SOURCES "*.asm")

add_executable (bf ${ASM_SOURCES})
