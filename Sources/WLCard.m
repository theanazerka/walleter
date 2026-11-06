#import "WLCard.h"
#import "WLBarcodeRenderer.h"
#import "WLBrand.h"
#import "WLColors.h"
#import "WLIcon.h"
#import "WLCardStore.h"

NSString *WLBarcodeFormatName(WLBarcodeFormat format) {
    switch (format) {
        case WLBarcodeFormatEAN13:   return @"EAN-13";
        case WLBarcodeFormatEAN8:    return @"EAN-8";
        case WLBarcodeFormatCode128: return @"Code 128";
        case WLBarcodeFormatQR:      return @"QR-код";
        case WLBarcodeFormatPDF417:  return @"PDF417";
        case WLBarcodeFormatAztec:   return @"Aztec";
        case WLBarcodeFormatNone:    return @"Без штрихкода";
        default:                     return @"?";
    }
}

BOOL WLBarcodeFormatIsLinear(WLBarcodeFormat format) {
    return format == WLBarcodeFormatEAN13 || format == WLBarcodeFormatEAN8 || format == WLBarcodeFormatCode128;
}

NSArray *WLBarcodeFormatDisplayOrder(void) {
    return @[ @(WLBarcodeFormatEAN13), @(WLBarcodeFormatEAN8), @(WLBarcodeFormatCode128),
              @(WLBarcodeFormatQR), @(WLBarcodeFormatPDF417), @(WLBarcodeFormatAztec), @(WLBarcodeFormatNone) ];
}

static NSString *WLTrim(NSString *s) {
    return [s ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@implementation WLCard

+ (instancetype)newCard {
    WLCard *card = [[WLCard alloc] init];
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    card.identifier = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    CFRelease(uuid);
    card.storeName = @"";
    card.cardNumber = @"";
    card.holderName = @"";
    card.notes = @"";
    card.barcodeFormat = WLBarcodeFormatEAN13;
    card.colorIndex = 0;
    card.created = [NSDate date];
    return card;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        _identifier = [coder decodeObjectForKey:@"identifier"];
        _storeName = [coder decodeObjectForKey:@"storeName"] ?: @"";
        _cardNumber = [coder decodeObjectForKey:@"cardNumber"] ?: @"";
        _holderName = [coder decodeObjectForKey:@"holderName"] ?: @"";
        _notes = [coder decodeObjectForKey:@"notes"] ?: @"";
        _barcodeFormat = [coder decodeIntegerForKey:@"barcodeFormat"];
        if (_barcodeFormat < 0 || _barcodeFormat >= WLBarcodeFormatCount) _barcodeFormat = WLBarcodeFormatCode128;
        _colorIndex = [coder decodeIntegerForKey:@"colorIndex"];
        _brandId = [coder decodeObjectForKey:@"brandId"];
        _hasCustomLogo = [coder decodeBoolForKey:@"hasCustomLogo"];
        _created = [coder decodeObjectForKey:@"created"] ?: [NSDate date];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_identifier forKey:@"identifier"];
    [coder encodeObject:_storeName forKey:@"storeName"];
    [coder encodeObject:_cardNumber forKey:@"cardNumber"];
    [coder encodeObject:_holderName forKey:@"holderName"];
    [coder encodeObject:_notes forKey:@"notes"];
    [coder encodeInteger:_barcodeFormat forKey:@"barcodeFormat"];
    [coder encodeInteger:_colorIndex forKey:@"colorIndex"];
    [coder encodeObject:_brandId forKey:@"brandId"];
    [coder encodeBool:_hasCustomLogo forKey:@"hasCustomLogo"];
    [coder encodeObject:_created forKey:@"created"];
}

- (id)copyWithZone:(NSZone *)zone {
    WLCard *c = [[WLCard allocWithZone:zone] init];
    c.identifier = _identifier;
    c.storeName = _storeName;
    c.cardNumber = _cardNumber;
    c.holderName = _holderName;
    c.notes = _notes;
    c.barcodeFormat = _barcodeFormat;
    c.colorIndex = _colorIndex;
    c.brandId = _brandId;
    c.hasCustomLogo = _hasCustomLogo;
    c.created = _created;
    return c;
}

- (WLBrand *)brand {
    return [WLBrand brandWithIdentifier:self.brandId];
}

- (BOOL)usesBrandColors {
    return self.colorIndex < 0 && self.brand != nil;
}

- (UIColor *)backgroundColor {
    return self.usesBrandColors ? self.brand.backgroundColor : WLColorBackground(MAX(self.colorIndex, 0));
}

- (UIColor *)foregroundColor {
    return self.usesBrandColors ? self.brand.foregroundColor : WLColorForeground(MAX(self.colorIndex, 0));
}

- (UIImage *)customLogo {
    if (!self.hasCustomLogo) return nil;
    return [UIImage imageWithContentsOfFile:[WLCardStore logoPathForIdentifier:self.identifier]];
}

- (NSString *)glyph {
    if (self.brand) return self.brand.glyph;
    NSString *name = WLTrim(self.storeName);
    return name.length ? [[name substringToIndex:1] uppercaseString] : @"W";
}

- (UIImage *)iconWithSide:(CGFloat)side scale:(CGFloat)scale {
    UIImage *custom = [self customLogo];
    if (!custom && self.brand.logo) return [self.brand iconWithSide:side scale:scale];
    return WLIconImage(side, scale, self.backgroundColor, self.foregroundColor, [self glyph], custom);
}

- (NSString *)validationError {
    if (WLTrim(self.storeName).length == 0) return @"Укажите название магазина.";
    NSString *number = WLTrim(self.cardNumber);
    if (number.length == 0) return @"Укажите номер карты.";
    switch (self.barcodeFormat) {
        case WLBarcodeFormatEAN13:   return [WLBarcodeRenderer ean13ValidationError:number];
        case WLBarcodeFormatEAN8:    return [WLBarcodeRenderer ean8ValidationError:number];
        case WLBarcodeFormatCode128: return [WLBarcodeRenderer code128ValidationError:number];
        default:                     return nil;
    }
}

- (NSString *)normalizedBarcodeMessage {
    NSString *number = WLTrim(self.cardNumber);
    if (self.barcodeFormat == WLBarcodeFormatEAN13) return [WLBarcodeRenderer ean13FullNumber:number] ?: number;
    if (self.barcodeFormat == WLBarcodeFormatEAN8) return [WLBarcodeRenderer ean8FullNumber:number] ?: number;
    return number;
}

@end
