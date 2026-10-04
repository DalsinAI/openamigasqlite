/* OpenBrowser: POSIX calls SQLite's unix VFS uses that libnix lacks. AmigaOS
 * files have no Unix owner or mode bits to change, so these succeed and do
 * nothing. MIT, Copyright (c) 2026 Dalsin Limited. */
#include <sys/types.h>
int fchmod(int fd, mode_t mode) { (void)fd; (void)mode; return 0; }
int fchown(int fd, uid_t owner, gid_t group) { (void)fd; (void)owner; (void)group; return 0; }
