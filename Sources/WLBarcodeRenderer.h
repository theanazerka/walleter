#import <UIKit/UIKit.h>

/// Рисует линейные штрихкоды (EAN-13, Code 128), которых нет в Passbook на iOS 6.
@interface WLBarcodeRenderer : NSObject

+ (NSString *)ean13ValidationError:(NSString *)number;
/// 12 или 13 цифр -> 13 цифр с контрольной; nil, если некорректно
+ (NSString *)ean13FullNumber:(NSString *)number;
+ (NSString *)code128ValidationError:(NSString *)text;

/// Строка модулей '1'/'0' без тихих зон; nil, если закодировать нельзя
+ (NSString *)ean13Modules:(NSString *)number;
+ (NSString *)code128Modules:(NSString *)text;

/// Картинка штрихкода на белой плашке. size — в точках, scale — 1 или 2.
+ (UIImage *)imageWithModules:(NSString *)modules caption:(NSString *)caption size:(CGSize)size scale:(CGFloat)scale;

@end
