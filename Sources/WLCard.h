#import <UIKit/UIKit.h>

// Значения хранятся в архиве — новые добавлять только в конец.
typedef NS_ENUM(NSInteger, WLBarcodeFormat) {
    WLBarcodeFormatEAN13 = 0,   // рисуется картинкой (Passbook в iOS 6 не умеет EAN)
    WLBarcodeFormatCode128,     // рисуется картинкой
    WLBarcodeFormatQR,          // нативно Passbook
    WLBarcodeFormatPDF417,      // нативно Passbook
    WLBarcodeFormatAztec,       // нативно Passbook
    WLBarcodeFormatNone,        // только номер
    WLBarcodeFormatEAN8,        // рисуется картинкой
    WLBarcodeFormatCount
};

NSString *WLBarcodeFormatName(WLBarcodeFormat format);
BOOL WLBarcodeFormatIsLinear(WLBarcodeFormat format);
/// Порядок показа в списке выбора
NSArray *WLBarcodeFormatDisplayOrder(void);

@class WLBrand;

@interface WLCard : NSObject <NSCoding, NSCopying>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *storeName;
@property (nonatomic, copy) NSString *cardNumber;
@property (nonatomic, copy) NSString *holderName;
@property (nonatomic, copy) NSString *notes;
@property (nonatomic, assign) WLBarcodeFormat barcodeFormat;
/// индекс палитры; -1 — фирменные цвета магазина
@property (nonatomic, assign) NSInteger colorIndex;
/// идентификатор пресета магазина (WLBrand) или nil
@property (nonatomic, copy) NSString *brandId;
/// есть свой логотип (картинка лежит в WLCardStore logoPathForIdentifier:)
@property (nonatomic, assign) BOOL hasCustomLogo;
@property (nonatomic, strong) NSDate *created;

+ (instancetype)newCard;
- (WLBrand *)brand;
- (BOOL)usesBrandColors;
- (UIColor *)backgroundColor;
- (UIColor *)foregroundColor;
- (UIImage *)customLogo;
- (UIImage *)iconWithSide:(CGFloat)side scale:(CGFloat)scale;

/// nil, если всё ок; иначе текст ошибки для пользователя
- (NSString *)validationError;
/// Номер, который реально уйдёт в штрихкод (для EAN — с контрольной цифрой)
- (NSString *)normalizedBarcodeMessage;
@end
