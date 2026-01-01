add_library(bpftime-agent SHARED
  agent.cpp
)


if(${BPFTIME_BUILD_WITH_LIBBPF})
  add_dependencies(bpftime-agent FridaGum spdlog::spdlog bpftime_frida_uprobe_attach_impl bpftime_syscall_trace_attach_impl)
else()
  add_dependencies(bpftime-agent FridaGum spdlog::spdlog bpftime_frida_uprobe_attach_impl)
endif()

set_target_properties(bpftime-agent PROPERTIES CXX_STANDARD 20 LINK_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/agent.version)

if(UNIX AND NOT APPLE)
  target_link_options(bpftime-agent PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/agent.version)
endif()

if(${TEST_LCOV})
  target_compile_options(bpftime-agent PRIVATE -fprofile-arcs -ftest-coverage -fprofile-update=atomic)
  target_link_options(bpftime-agent PRIVATE -fprofile-arcs)
endif()

# Force link VM compat libraries so constructor-based factory registration is retained
if(${BPFTIME_UBPF_JIT})
  add_dependencies(bpftime-agent bpftime_ubpf_vm)
  if(APPLE)
    target_link_options(bpftime-agent PUBLIC "-Wl,-force_load,$<TARGET_FILE:bpftime_ubpf_vm>")
  else()
    target_link_options(bpftime-agent PUBLIC "-Wl,--whole-archive" "$<TARGET_FILE:bpftime_ubpf_vm>" "-Wl,--no-whole-archive")
  endif()
  target_link_libraries(bpftime-agent PUBLIC bpftime_ubpf_vm)
endif()

if(${BPFTIME_LLVM_JIT})
  add_dependencies(bpftime-agent bpftime_llvm_vm llvmbpf_vm)
  if(APPLE)
    target_link_options(bpftime-agent PUBLIC "-Wl,-force_load,$<TARGET_FILE:bpftime_llvm_vm>")
  else()
    target_link_options(bpftime-agent PUBLIC "-Wl,--whole-archive" "$<TARGET_FILE:bpftime_llvm_vm>" "-Wl,--no-whole-archive")
  endif()
  target_link_libraries(bpftime-agent PUBLIC bpftime_llvm_vm)
  # Statically embed the compat_llvm constructor TU to guarantee VM factory registration in LD_PRELOAD context
  target_sources(bpftime-agent PRIVATE $<TARGET_OBJECTS:bpftime_llvm_vm_obj>)
endif()

if(${BPFTIME_ENABLE_CUDA_ATTACH})
  add_dependencies(bpftime-agent bpftime_llvm_vm llvmbpf_vm bpftime_vm)
  if(APPLE)
    target_link_options(bpftime-agent PUBLIC 
      "-Wl,-force_load,$<TARGET_FILE:bpftime_nv_attach_impl>"
      "-Wl,-force_load,$<TARGET_FILE:bpftime_llvm_vm>"
      "-Wl,-force_load,$<TARGET_FILE:bpftime_vm>"
      "-Wl,-force_load,$<TARGET_FILE:llvmbpf_vm>")
  else()
    target_link_options(bpftime-agent PUBLIC "-Wl,--whole-archive" "$<TARGET_FILE:bpftime_nv_attach_impl>" "$<TARGET_FILE:bpftime_llvm_vm>" "$<TARGET_FILE:bpftime_vm>" "$<TARGET_FILE:llvmbpf_vm>" "-Wl,--no-whole-archive")
  endif()
  target_link_libraries(bpftime-agent PUBLIC bpftime_nv_attach_impl)
  target_include_directories(bpftime-agent PUBLIC ${NV_ATTACH_IMPL_INCLUDE})
  set(EXTRA_LINK_LIBS bpftime_llvm_vm
    bpftime_vm
    llvmbpf_vm)
endif()


# Set platform-specific link libraries
if(APPLE)
  set(PLATFORM_LIBS -lpthread -lm)
else()
  set(PLATFORM_LIBS -lpthread -lm -ldl)
endif()

if(${BPFTIME_BUILD_WITH_LIBBPF})
  target_include_directories(bpftime-agent
    PRIVATE
    ${FRIDA_GUM_INSTALL_DIR}
    ../include
    ../../third_party/
    ${SPDLOG_INCLUDE}
    ${FRIDA_UPROBE_ATTACH_IMPL_INCLUDE}
    ${SYSCALL_TRACE_ATTACH_IMPL_INCLUDE}
    ${NV_ATTACH_IMPL_INCLUDE}
  )
  target_link_libraries(bpftime-agent
    PUBLIC
    ${FRIDA_GUM_INSTALL_DIR}/libfrida-gum.a
    runtime
    ${PLATFORM_LIBS}
    spdlog::spdlog
    bpftime_frida_uprobe_attach_impl
    bpftime_syscall_trace_attach_impl
    ${EXTRA_LINK_LIBS}
  )

else()
  target_include_directories(bpftime-agent
    PRIVATE
    ${FRIDA_GUM_INSTALL_DIR}
    ../include
    ../../third_party/
    ${SPDLOG_INCLUDE}
    ${FRIDA_UPROBE_ATTACH_IMPL_INCLUDE}

  )
  target_link_libraries(bpftime-agent
    ${FRIDA_GUM_INSTALL_DIR}/libfrida-gum.a
    runtime
    ${PLATFORM_LIBS}
    spdlog::spdlog
    bpftime_frida_uprobe_attach_impl
    ${EXTRA_LINK_LIBS}
  )
endif()
if(APPLE)
  target_link_options(bpftime-agent PUBLIC "-Wl,-export_dynamic")
else()
  target_link_options(bpftime-agent PUBLIC "-Wl,-export-dynamic")
endif()
