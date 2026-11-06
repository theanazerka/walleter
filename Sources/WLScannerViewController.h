#import <UIKit/UIKit.h>
#import "WLBarcodeDecoder.h"

/// Камера + ZBar. Показывать внутри UINavigationController модально.
@interface WLScannerViewController : UIViewController
- (id)initWithCompletion:(void (^)(WLScanResult *result))completion;   // result == nil — отмена
+ (BOOL)isCameraAvailable;
@end
