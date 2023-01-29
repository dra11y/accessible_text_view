#import "AccessibleTextViewPlugin.h"
#if __has_include(<accessible_text_view/accessible_text_view-Swift.h>)
#import <accessible_text_view/accessible_text_view-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "accessible_text_view-Swift.h"
#endif

@implementation AccessibleTextViewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAccessibleTextViewPlugin registerWithRegistrar:registrar];
}
@end
