#import "Logger.h"
#import <UIKit/UIKit.h>
#include <signal.h>
#include <execinfo.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <exception>
#import "fishhook.h"

static char g_logPath[1024] = {0};

const char *getLogFilePathCString(void) {
    if (g_logPath[0] == '\0') {
        NSString *docs = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        [[NSFileManager defaultManager] createDirectoryAtPath:docs withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *path = [docs stringByAppendingPathComponent:@"tweak_debug.txt"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        }
        snprintf(g_logPath, sizeof(g_logPath), "%s", [path UTF8String]);
    }
    return g_logPath;
}

void tweakLog(NSString *format, ...) {
    if (!format) return;
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSLog(@"%@", msg);

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString *timestamp = [df stringFromDate:[NSDate date]];

    NSString *line = [NSString stringWithFormat:@"%@ %@\n", timestamp, msg];
    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];

    const char *cpath = getLogFilePathCString();
    if (cpath && cpath[0] != '\0') {
        int fd = open(cpath, O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (fd >= 0) {
            write(fd, [data bytes], [data length]);
            fsync(fd);
            close(fd);
        }
    }
}

#pragma mark - Crash Traps & Interceptions

static NSUncaughtExceptionHandler *g_wa_uncaught_handler = NULL;

static void our_uncaughtExceptionHandler(NSException *exception) {
    NSString *reason = [exception reason];
    NSString *name = [exception name];
    NSArray *symbols = [exception callStackSymbols];

    NSMutableString *crashReport = [NSMutableString stringWithFormat:
        @"\n==================== CRASH: UNCAUGHT EXCEPTION ====================\n"
        @"Name: %@\n"
        @"Reason: %@\n"
        @"Call Stack:\n", name ?: @"(unknown)", reason ?: @"(no reason)"];

    for (NSString *sym in symbols) {
        [crashReport appendFormat:@"  %@\n", sym];
    }
    [crashReport appendString:@"===================================================================\n\n"];

    tweakLog(@"%@", crashReport);

    if (g_wa_uncaught_handler) {
        g_wa_uncaught_handler(exception);
    }
}

static void (*orig_NSSetUncaughtExceptionHandler)(NSUncaughtExceptionHandler *);
static void hook_NSSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *handler) {
    WATweakLog(@"Intercepted NSSetUncaughtExceptionHandler -> chaining handler: %p", handler);
    g_wa_uncaught_handler = handler;
    if (orig_NSSetUncaughtExceptionHandler) {
        orig_NSSetUncaughtExceptionHandler(our_uncaughtExceptionHandler);
    }
}

static void our_signalHandler(int sig, siginfo_t *info, void *context) {
    const char *cpath = getLogFilePathCString();
    int fd = open(cpath, O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (fd >= 0) {
        char header[256];
        snprintf(header, sizeof(header), "\n==================== CRASH: SIGNAL %d ====================\n", sig);
        write(fd, header, strlen(header));

        void *callstack[128];
        int frames = backtrace(callstack, 128);
        backtrace_symbols_fd(callstack, frames, fd);

        const char *footer = "==========================================================\n\n";
        write(fd, footer, strlen(footer));
        fsync(fd);
        close(fd);
    }
    _exit(128 + sig);
}

static int (*orig_sigaction)(int, const struct sigaction *, struct sigaction *);
static int hook_sigaction(int signum, const struct sigaction *act, struct sigaction *oldact) {
    if (signum == SIGSEGV || signum == SIGBUS || signum == SIGABRT ||
        signum == SIGILL || signum == SIGTRAP || signum == SIGFPE || signum == SIGSYS) {
        if (oldact && orig_sigaction) {
            orig_sigaction(signum, NULL, oldact);
        }
        struct sigaction sa;
        memset(&sa, 0, sizeof(sa));
        sa.sa_sigaction = our_signalHandler;
        sa.sa_flags = SA_SIGINFO | SA_RESETHAND;
        return orig_sigaction ? orig_sigaction(signum, &sa, NULL) : 0;
    }
    return orig_sigaction ? orig_sigaction(signum, act, oldact) : 0;
}

static void hook_abort(void) {
    const char *cpath = getLogFilePathCString();
    int fd = open(cpath, O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (fd >= 0) {
        const char *msg = "\n==================== CRASH: abort() CALLED ====================\n";
        write(fd, msg, strlen(msg));
        void *callstack[128];
        int frames = backtrace(callstack, 128);
        backtrace_symbols_fd(callstack, frames, fd);
        const char *footer = "===============================================================\n\n";
        write(fd, footer, strlen(footer));
        fsync(fd);
        close(fd);
    }
    _exit(134);
}

static void (*orig_exit)(int);
static void hook_exit(int status) {
    if (status != 0) {
        const char *cpath = getLogFilePathCString();
        int fd = open(cpath, O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (fd >= 0) {
            char header[256];
            snprintf(header, sizeof(header), "\n==================== CRASH: exit(%d) CALLED ====================\n", status);
            write(fd, header, strlen(header));
            void *callstack[128];
            int frames = backtrace(callstack, 128);
            backtrace_symbols_fd(callstack, frames, fd);
            const char *footer = "================================================================\n\n";
            write(fd, footer, strlen(footer));
            fsync(fd);
            close(fd);
        }
    }
    if (orig_exit) orig_exit(status);
    _exit(status);
}

static void cppTerminateHandler(void) {
    const char *cpath = getLogFilePathCString();
    int fd = open(cpath, O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (fd >= 0) {
        const char *header = "\n==================== CRASH: C++ std::terminate ====================\n";
        write(fd, header, strlen(header));
        void *callstack[128];
        int frames = backtrace(callstack, 128);
        backtrace_symbols_fd(callstack, frames, fd);
        const char *footer = "===================================================================\n\n";
        write(fd, footer, strlen(footer));
        fsync(fd);
        close(fd);
    }
    _exit(1);
}

void installCrashHandler(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        getLogFilePathCString();

        NSSetUncaughtExceptionHandler(&our_uncaughtExceptionHandler);
        std::set_terminate(cppTerminateHandler);

        struct sigaction sa;
        memset(&sa, 0, sizeof(sa));
        sa.sa_sigaction = our_signalHandler;
        sa.sa_flags = SA_SIGINFO | SA_RESETHAND;

        sigaction(SIGSEGV, &sa, NULL);
        sigaction(SIGBUS, &sa, NULL);
        sigaction(SIGABRT, &sa, NULL);
        sigaction(SIGILL, &sa, NULL);
        sigaction(SIGTRAP, &sa, NULL);
        sigaction(SIGFPE, &sa, NULL);
        sigaction(SIGSYS, &sa, NULL);

        rebind_symbols(
            (struct rebinding[]){
                {"NSSetUncaughtExceptionHandler", (void*)hook_NSSetUncaughtExceptionHandler, (void**)&orig_NSSetUncaughtExceptionHandler},
                {"sigaction", (void*)hook_sigaction, (void**)&orig_sigaction},
                {"abort", (void*)hook_abort, NULL},
                {"exit", (void*)hook_exit, (void**)&orig_exit},
            },
            4
        );

        WATweakLog(@"Crash handler fully armed (Exceptions + Signals + C++ terminate + fishhook traps).");
    });
}
