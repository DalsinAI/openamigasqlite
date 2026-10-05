#!/bin/sh
# openamigasqlite: SQLite, built for AmigaOS 3.x (68020 + FPU) with the
# os32-gcc16 compiler (bebbo's amiga-gcc, GCC 16.2, libnix, libpthread).
# MIT, Copyright (c) 2026 Dalsin Limited. The library keeps its own licence.
#
#   OS32_GCC16   compiler root holding prefix/ and compat/
#                (default ~/AmigaChrome/stoves/os32-gcc16)
#   PREFIX       where include/ and lib/ go (default ./out)
#   TARBALLS     folder holding the upstream tarballs listed in SOURCES
#                (default ./tarballs); the script checks their SHA-256
#   JOBS         parallel jobs for CMake/make builds (default 2)
#
# usage: ./build.sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
S=${OS32_GCC16:-"$HOME/AmigaChrome/stoves/os32-gcc16"}
P=$S/prefix
OUT=${PREFIX:-"$HERE/out"}
TARBALLS=${TARBALLS:-"$HERE/tarballs"}
JOBS=${JOBS:-2}
WORK="$HERE/work"
CC="$P/bin/m68k-amigaos-gcc"
CXX="$P/bin/m68k-amigaos-g++"
AR="$P/bin/m68k-amigaos-ar"
CPU=${OS32_CPU_FLAGS:-"-m68020 -m68881 -mcrt=nix20"}
CFLAGS="-O2 $CPU -D_DEFAULT_SOURCE=1 -D_POSIX_TIMERS=1 -D_POSIX_REALTIME_SIGNALS=1 -fno-common"
mkdir -p "$OUT/include" "$OUT/lib" "$WORK"

# unpack NAME TARBALL SHA256: check the tarball and unpack it into $WORK
unpack() {
    t="$TARBALLS/$2"
    [ -f "$t" ] || { echo "missing $t (see SOURCES)"; exit 2; }
    echo "$3  $t" | sha256sum -c - >/dev/null || { echo "SHA-256 mismatch: $t"; exit 2; }
    rm -rf "$WORK/$1"; mkdir -p "$WORK/$1"
    case "$2" in
        *.zip) (cd "$WORK/$1" && unzip -q "$t") ;;
        *) tar xf "$t" -C "$WORK/$1" ;;
    esac
}

# archive NAME FILE...: compile into $OUT/lib/libNAME.a ($XFLAGS added)
archive() {
    name=$1; shift
    obj="$WORK/obj-$name"
    rm -rf "$obj"; mkdir -p "$obj"
    for f in "$@"; do
        o="$obj/$(echo "$f" | tr '/' '_' | sed 's/\.[a-z]*$//').o"
        case "$f" in
            *.cc|*.cpp) $CXX $CFLAGS ${XFLAGS:-} -c "$f" -o "$o" ;;
            *) $CC $CFLAGS ${XFLAGS:-} -c "$f" -o "$o" ;;
        esac
    done
    rm -f "$OUT/lib/lib$name.a"
    $AR rcs "$OUT/lib/lib$name.a" "$obj"/*.o
    echo "lib$name.a: $(wc -c < "$OUT/lib/lib$name.a") bytes"
}

unpack sqlite sqlite-amalgamation-3530400.zip 1e71ddf93849c6a6ecf58b827c0692073d2dd7ee40196158068f7b29f422e87d
cd "$WORK/sqlite/sqlite-amalgamation-3530400"
patch -p1 < "$HERE/patches/sqlite-3.53.4-amiga-paths.patch"
# One process, no shared memory: no WAL and no mmap. Programs make the
# "unix-none" VFS (no POSIX file locks) the default at start.
XFLAGS="-DSQLITE_THREADSAFE=1 -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_OMIT_WAL -DSQLITE_MAX_MMAP_SIZE=0 \
    -DSQLITE_DEFAULT_MEMSTATUS=0 -DSQLITE_OMIT_DEPRECATED -DSQLITE_DQS=0 -DHAVE_USLEEP=1 -DSQLITE_OS_UNIX=1" \
    archive sqlite3 sqlite3.c "$HERE/compat/sqlite_amiga.c"
cp sqlite3.h sqlite3ext.h "$OUT/include/"
