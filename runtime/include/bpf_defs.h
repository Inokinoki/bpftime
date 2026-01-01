/* SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2022, eunomia-bpf org
 * All rights reserved.
 *
 * Cross-platform BPF definitions header.
 * On Linux, includes the real linux/bpf.h
 * On macOS/other platforms, includes the polyfill from bpftime_epoll.h
 */
#ifndef BPFTIME_BPF_DEFS_H
#define BPFTIME_BPF_DEFS_H

#if __linux__
#include <linux/bpf.h>
#elif __APPLE__
#include "bpftime_epoll.h"
// Use the bpftime_epoll namespace for bpf types on macOS
using namespace bpftime_epoll;
#else
#error "Unsupported platform"
#endif

#endif /* BPFTIME_BPF_DEFS_H */
