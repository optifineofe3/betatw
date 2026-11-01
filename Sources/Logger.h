#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

void tweakLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
void installCrashHandler(void);

#ifdef __cplusplus
}
#endif

#define WATweakLog(fmt, ...) tweakLog((@"[WATweak] " fmt), ##__VA_ARGS__)
