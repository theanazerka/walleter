#import "WLCard.h"
#import "WLBarcodeRenderer.h"

NSString *WLBarcodeFormatName(WLBarcodeFormat format) {
    switch (format) {
        case WLBarcodeFormatEAN13:   return @"EAN-13";
        case WLBarcodeFormatCode128: return @"Code 128";
        case WLBarcodeFormatQR:      return @"QR-код";
        case WLBarcodeFormatPDF417:  return @"PDF417";
        case WLBarcodeFormatAztec:   return @"Aztec";
        case WLBarcodeFormatNone:    return @"Без штрихкода";
        default:                     return @"?";
    }
}

BOOL WLBarcodeFormatIsLinear(WLBarcodeFormat format) {
    return format == WLBarcodeFormatEAN13 || format == WLBarcodeFormatCode128;
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
        _colorIndex = [coder decodeIntegerForKey:@"colorIndex"];
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
    c.created = _created;
    return c;
}

- (NSString *)validationError {
    if (WLTrim(self.storeName).length == 0) return @"Укажите название магазина.";
    NSString *number = WLTrim(self.cardNumber);
    if (number.length == 0) return @"Укажите номер карты.";
    switch (self.barcodeFormat) {
        case WLBarcodeFormatEAN13:
            return [WLBarcodeRenderer ean13ValidationError:number];
        case WLBarcodeFormatCode128:
            return [WLBarcodeRenderer code128ValidationError:number];
        default:
            return nil;
    }
}

- (NSString *)normalizedBarcodeMessage {
    NSString *number = WLTrim(self.cardNumber);
    if (self.barcodeFormat == WLBarcodeFormatEAN13) {
        return [WLBarcodeRenderer ean13FullNumber:number] ?: number;
    }
    return number;
}

@end
