/* cosmocc resolves these at runtime; busybox needs compile-time values. bone targets Linux only. */
#ifdef __ASSEMBLER__
/* cosmocc rejects objects with no symbols, which #if-ed out asm files produce. */
bone_asm_anchor:
#else
#include <signal.h>
#include <sys/socket.h>

#undef SIGBUS
#undef SIGCHLD
#undef SIGCONT
#undef SIGPWR
#undef SIGSTOP
#undef SIGSYS
#undef SIGTSTP
#undef SIGURG
#undef SIGUSR1
#undef SIGUSR2
#undef SIGSTKFLT
#define SIGBUS 7
#define SIGUSR1 10
#define SIGUSR2 12
#define SIGSTKFLT 16
#define SIGCHLD 17
#define SIGCONT 18
#define SIGSTOP 19
#define SIGTSTP 20
#define SIGURG 23
#define SIGPWR 30
#define SIGSYS 31

#undef AF_UNSPEC
#undef AF_UNIX
#undef AF_INET
#undef AF_INET6
#undef AF_PACKET
#undef AF_NETLINK
#undef SOCK_STREAM
#undef SOCK_DGRAM
#undef SOCK_RAW
#undef SOCK_RDM
#undef SOCK_SEQPACKET
#define AF_UNSPEC 0
#define AF_UNIX 1
#define AF_INET 2
#define AF_INET6 10
#define AF_NETLINK 16
#define AF_PACKET 17
#define SOCK_STREAM 1
#define SOCK_DGRAM 2
#define SOCK_RAW 3
#define SOCK_RDM 4
#define SOCK_SEQPACKET 5
#endif
