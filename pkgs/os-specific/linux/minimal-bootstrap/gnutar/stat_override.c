#include <sys/stat.h>
#include <linux/syscall.h>
#include <linux/x86/syscall.h>

int _lstat(const char *path, struct stat *buf) {
  int rc = lstat(path, buf);
  if (rc == 0) {
    buf->st_atime = 0;
    buf->st_mtime = 0;
  }
  return rc;
}

/* tar's src/system.h aliases lstat to stat with mes libc, so override stat. */
#define stat(a, b) _lstat(a, b)
