#!/bin/bash

# Generate syscall ID table for the current platform
# Output format: static const char* table=R"(syscall_name number\n...)";

OUTPUT_FILE=$1

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: syscall numbers are in <sys/syscall.h> with SYS_ prefix
    echo "static const char* table=R\"(" > "$OUTPUT_FILE"
    echo -e '#include <sys/syscall.h>' | \
        cpp -dM 2>/dev/null | grep '#define SYS_.*[0-9]$' | \
        sed 's/#define SYS_//' | awk '{print $1, $2}' >> "$OUTPUT_FILE"
    echo ")\";" >> "$OUTPUT_FILE"
else
    # Linux: syscall numbers are in <sys/syscall.h> with __NR_ prefix
    echo "static const char* table=R\"(" > "$OUTPUT_FILE"
    echo -e '#include <sys/syscall.h>' | \
        cpp -dM | grep '#define __NR_.*[0-9]$' | \
        cut -d' ' -f 2,3 | cut -d_ -f 4- >> "$OUTPUT_FILE"
    echo ")\";" >> "$OUTPUT_FILE"
fi
