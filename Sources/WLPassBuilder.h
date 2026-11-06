#import <Foundation/Foundation.h>
#import "WLCard.h"

extern NSString *const WLPassTypeIdentifier;

/// Собирает неподписанный .pkpass (manifest.json есть, signature нет).
/// Passbook примет его только с установленным твиком SigPass.
@interface WLPassBuilder : NSObject
+ (NSData *)pkpassDataForCard:(WLCard *)card error:(NSString **)error;
@end
