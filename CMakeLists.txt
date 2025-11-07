cmake_minimum_required(VERSION 3.20)
project(max_strict_repo LANGUAGES C CXX)

# 1) Always emit compile_commands.json for tooling like clang-tidy and ccflags_doctor.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "" FORCE)

# 2) Standards (no GNU extensions)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 3) Strict toggles (C++)
option(STRICT_NO_EXCEPTIONS "Ban exceptions at compile time (C++)" ON)
option(STRICT_NO_RTTI       "Ban RTTI at compile time (C++)"       ON)

# 4) Global policy-aligned warnings & hardening, applied via an INTERFACE target.
add_library(global_compile_options INTERFACE)

# Baseline flags (both C and C++)
target_compile_options(global_compile_options INTERFACE
  -Wall -Wextra -Wpedantic -Werror
  -Wshadow -Wconversion -Wsign-conversion
  -Wformat=2 -Wnull-dereference
  -Wswitch-enum
  -fno-strict-aliasing
  -fvisibility=hidden

  # C-only extras
  $<$<COMPILE_LANGUAGE:C>:-Wdouble-promotion -Wcast-qual -Wmissing-declarations>

  # C++-only extras
  $<$<COMPILE_LANGUAGE:CXX>:-Wold-style-cast -Woverloaded-virtual -Wnon-virtual-dtor>

  # GCC-only (Clang doesn’t support -Wsuggest-override; guard it)
  $<$<AND:$<CXX_COMPILER_ID:GNU>,$<COMPILE_LANGUAGE:CXX>>:-Wsuggest-override>

  # Ban exceptions/RTTI if toggled (C++ only)
  $<$<AND:$<BOOL:${STRICT_NO_EXCEPTIONS}>,$<COMPILE_LANGUAGE:CXX>>:-fno-exceptions>
  $<$<AND:$<BOOL:${STRICT_NO_RTTI}>,$<COMPILE_LANGUAGE:CXX>>:-fno-rtti>
)

# 5) PIC is a sensible default for libs on most platforms
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# 6) Probe targets so compile_commands.json exists even with no real code yet.
#    Include BOTH C and C++ so ccflags_doctor sees C++-only flags like -fno-exceptions/-fno-rtti.
if(NOT EXISTS "${CMAKE_BINARY_DIR}/__probe__.c")
  file(WRITE "${CMAKE_BINARY_DIR}/__probe__.c" "int __probe__(void){return 0;}\n")
endif()
if(NOT EXISTS "${CMAKE_BINARY_DIR}/__probe__.cpp")
  file(WRITE "${CMAKE_BINARY_DIR}/__probe__.cpp" "int __probe_cpp__(void){return 0;}\n")
endif()

add_library(__compile_db_probe_c STATIC "${CMAKE_BINARY_DIR}/__probe__.c")
target_link_libraries(__compile_db_probe_c PRIVATE global_compile_options)
set_target_properties(__compile_db_probe_c PROPERTIES EXCLUDE_FROM_ALL YES)

add_library(__compile_db_probe_cxx STATIC "${CMAKE_BINARY_DIR}/__probe__.cpp")
target_link_libraries(__compile_db_probe_cxx PRIVATE global_compile_options)
set_target_properties(__compile_db_probe_cxx PROPERTIES EXCLUDE_FROM_ALL YES)

# 7) When you add real targets later, just:
# add_library(foo src/foo.c)
# target_link_libraries(foo PRIVATE global_compile_options)
