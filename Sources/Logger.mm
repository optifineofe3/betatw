#import "Logger.h"
#import <UIKit/UIKit.h>
#include <signal.h>
#include <execinfo.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <exception>

static NSString *getLogFilePath(void) {
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *docs = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        [[NSFileManager defaultManager] createDirectoryAtPath:docs withIntermediateDirectories:YES attributes:nil error:nil];
        path = [docs stringByAppendingPathComponent:@"tweak_debug.txt"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        }
    });
    return path;
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

    NSString *path = getLogFilePath();
    if (path) {
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
        if (fh) {
            [fh seekToEndOfFile];
            [fh writeData:data];
            [fh synchronizeFile];
            [fh closeFile];
        }
    }
}

static void uncaughtExceptionHandler(NSException *exception) {
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
}

static void signalHandler(int sig, siginfo_t *info, void *context) {
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);

    NSString *docs = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/tweak_debug.txt"];
    int fd = open([docs UTF8String], O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (fd >= 0) {
        char header[256];
        snprintf(header, sizeof(header), "\n==================== CRASH: SIGNAL %d ====================\n", sig);
        write(fd, header, strlen(header));
        if (strs) {
            for (int i = 0; i < frames; ++i) {
                write(fd, strs[i], strlen(strs[i]));
                write(fd, "\n", 1);
            }
            free(strs);
        }
        const char *footer = "==========================================================\n\n";
        write(fd, footer, strlen(footer));
        close(fd);
    }
    _exit(128 + sig);
}

static void cppTerminateHandler(void) {
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);

    NSString *docs = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/tweak_debug.txt"];
    int fd = open([docs UTF8String], O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (fd >= 0) {
        const char *header = "\n==================== CRASH: C++ std::terminate ====================\n";
        write(fd, header, strlen(header));
        if (strs) {
            for (int i = 0; i < frames; ++i) {
                write(fd, strs[i], strlen(strs[i]));
                write(fd, "\n", 1);
            }
            free(strs);
        }
        const char *footer = "===================================================================\n\n";
        write(fd, footer, strlen(footer));
        close(fd);
    }
    _exit(1);
}

void installCrashHandler(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
        std::set_terminate(cppTerminateHandler);

        struct sigaction sa;
        memset(&sa, 0, sizeof(sa));
        sa.sa_sigaction = signalHandler;
        sa.sa_flags = SA_SIGINFO | SA_RESETHAND;

        sigaction(SIGSEGV, &sa, NULL);
        sigaction(SIGBUS, &sa, NULL);
        sigaction(SIGABRT, &sa, NULL);
        sigaction(SIGILL, &sa, NULL);
        sigaction(SIGTRAP, &sa, NULL);
        sigaction(SIGFPE, &sa, NULL);
        sigaction(SIGSYS, &sa, NULL);

        tweakLog(@"[WATweak] Crash handler installed (Exceptions + Signals + C++ terminate).");
    });
}
