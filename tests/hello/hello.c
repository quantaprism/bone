#include <stdio.h>
#include <sys/utsname.h>

int main(void) {
  struct utsname u;
  uname(&u);
  printf("bone hello from %s/%s\n", u.sysname, u.machine);
  return 0;
}
