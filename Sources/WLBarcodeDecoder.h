#import <UIKit/UIKit.h>
#import "WLCard.h"

@interface WLScanResult : NSObject
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) WLBarcodeFormat format;   // как будем показывать в Passbook
@property (nonatomic, copy) NSString *symbologyName;    // что распознал ZBar
@end

/// Обёртка над ZBar. Экземпляр не потокобезопасен — используйте с одной очереди.
@interface WLBarcodeDecoder : NSObject
/// Кадр в оттенках серого (8 бит на пиксель). bytesPerRow может быть больше width.
- (WLScanResult *)decodeGray:(const uint8_t *)pixels width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow;
- (WLScanResult *)decodeImage:(UIImage *)image;
@end
