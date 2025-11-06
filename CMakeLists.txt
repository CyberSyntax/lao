cmake_minimum_required(VERSION 3.20)
project(max_strict_repo LANGUAGES C CXX)

# Standards (no GNU extensions)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Options to toggle ultra-strict knobs
option(STRICT_NO_EXCEPTIONS "Ban exceptions at compile time (C++)" ON)
option(STRICT_NO_RTTI       "Ban RTTI at compile time (C++)"       ON)

if(MSVC)
  add_compile_options(/W4 /WX /permissive- /EHs- /GR-)
else()
  add_compile_options(
    -Wall -Wextra -Wpedantic -Werror
    -Wcast-qual -Wold-style-cast -Woverloaded-virtual
    -Wnull-dereference -Wshadow -Wconversion -Wdouble-promotion
    -Wformat=2 -Wswitch-enum -Wmissing-declarations
    -Wnon-virtual-dtor -Wsuggest-override
  )
  if(STRICT_NO_EXCEPTIONS)
    add_compile_options(-fno-exceptions)
  endif()
  if(STRICT_NO_RTTI)
    add_compile_options(-fno-rtti)
  endif()
endif()

# This repo currently has placeholders only; provide a target if needed later.
# The main purpose today is to generate compile_commands.json deterministically.
