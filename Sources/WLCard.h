#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WLBarcodeFormat) {
    WLBarcodeFormatEAN13 = 0,   // рисуется картинкой (Passbook в iOS 6 не умеет EAN)
    WLBarcodeFormatCode128,     // рисуется картинкой
    WLBarcodeFormatQR,          // нативно Passbook
    WLBarcodeFormatPDF417,      // нативно Passbook
    WLBarcodeFormatAztec,       // нативно Passbook
    WLBarcodeFormatNone,        // только номер
    WLBarcodeFormatCount
};

NSString *WLBarcodeFormatName(WLBarcodeFormat format);
BOOL WLBarcodeFormatIsLinear(WLBarcodeFormat format);

@interface WLCard : NSObject <NSCoding, NSCopying>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *storeName;
@property (nonatomic, copy) NSString *cardNumber;
@property (nonatomic, copy) NSString *holderName;
@property (nonatomic, copy) NSString *notes;
@property (nonatomic, assign) WLBarcodeFormat barcodeFormat;
@property (nonatomic, assign) NSInteger colorIndex;
@property (nonatomic, strong) NSDate *created;

+ (instancetype)newCard;
/// nil, если всё ок; иначе текст ошибки для пользователя
- (NSString *)validationError;
/// Номер, который реально уйдёт в штрихкод (для EAN-13 — с контрольной цифрой)
- (NSString *)normalizedBarcodeMessage;
@end
