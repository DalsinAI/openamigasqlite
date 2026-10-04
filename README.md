# openamigasqlite

SQLite for AmigaOS 3.x on 68k, built as static link libraries for
GCC programs. Part of the [OpenAmiga](https://github.com/DalsinAI/openamiga)
ports, made for [OpenBrowser](https://github.com/DalsinAI/openamigabrowser),
the WebKit browser for AmigaOS 3.2.

**Status:** Working: builds, and the smoke test passes on the bench with the database on DH1:.

This repository holds the Amiga build, not SQLite itself: a build script,
patches, a smoke test and the upstream licences.

## Upstream

| Library | Version | Licence | Home |
| --- | --- | --- | --- |
| SQLite | 3.53.4 | public domain (see upstream/SQLITE-BLESSING.txt) | https://www.sqlite.org/ |

The exact files and their SHA-256 sums are in [SOURCES](SOURCES). All credit
for the library goes to its authors; see `upstream/` for their notices.

## What the Amiga port changes

- **AmigaDOS names.** The unix VFS turns every file name into a POSIX path, which breaks names like `T:a.db` (and a leading `/` means the parent directory on AmigaDOS). The patch keeps names as given (`patches/sqlite-3.53.4-amiga-paths.patch`).
- **`fchmod` and `fchown`.** libnix has neither; `compat/sqlite_amiga.c` supplies ones that succeed and do nothing, since AmigaOS files have no Unix owner or mode bits.
- **No WAL, no mmap, no extension loading.** These need shared memory or `dlopen`, which AmigaOS doesn't have.
- **Locking.** Programs call `sqlite3_vfs_register(sqlite3_vfs_find("unix-none"), 1)` before opening a database: libnix has no POSIX advisory locks.

## Building

You need the os32-gcc16 compiler (bebbo's amiga-gcc on GCC 16.2 with libnix
and libpthread; see DalsinAI/openamigabrowser `stove/`) and the upstream
tarballs from [SOURCES](SOURCES) in `tarballs/`. Then:

```
./build.sh
```

The libraries and headers land in `out/` (set `PREFIX` to change that). The
script prints which other settings it needs, if any. Target: 68020 or better
with an FPU (`-m68020 -m68881`), libnix (`-mcrt=nix20`).

Link with: `-lsqlite3 -lpthread`

## Tested

`tests/sqlitetest.c`, run on AmigaOS 3.2.3 on AmigaChrome's AC090 emulation (68040 with FPU, 256 MB), Instance-24, 4 October 2026, as `sqlitetest DH1:Probe/sqlt.db keep`:

```
SQLITE 3.53.4 vfs=unix-none
id=3 name=cookie v=-1.5 len=6
id=1 name=amiga v=3.2 len=5
id=2 name=webkit v=605.1 len=6
n=3 total=606.80000000000007 u=OK
SQLITE_DONE rc=0
```

The database file it wrote passes `PRAGMA integrity_check` in SQLite on Linux.

It has not yet been run on real Amiga hardware.

## Known issues

- In `RAM:` (`T:`), a fresh database gives "file is not a database" on the first statement. On DH1: it works. Not yet investigated, so keep databases on disk for now.

## Licence

Dalsin Limited's Amiga changes (the build script, patches, configuration
headers and tests) are MIT, Copyright (c) 2026 Dalsin Limited: see
[LICENSE](LICENSE). SQLite keeps its own licence, in
[upstream/](upstream/); a patch to its source stays under that licence.
