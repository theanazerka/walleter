#import <Foundation/Foundation.h>

/// Минимальный ZIP-архиватор (метод STORE, без сжатия) — этого достаточно для .pkpass.
@interface WLZipWriter : NSObject
- (void)addFileNamed:(NSString *)name data:(NSData *)data;
- (NSData *)archiveData;
@end
