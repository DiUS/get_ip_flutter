#import "GetIpPlugin.h"
#if __has_include(<get_ip/get_ip-Swift.h>)
#import <get_ip/get_ip-Swift.h>
#else
#import "get_ip-Swift.h"
#endif

@implementation GetIpPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftGetIpPlugin registerWithRegistrar:registrar];
}
@end
