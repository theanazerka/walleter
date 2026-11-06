#import "WLPassBuilder.h"
#import "WLZipWriter.h"
#import "WLBarcodeRenderer.h"
#import "WLColors.h"
#import "WLIcon.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>

NSString *const WLPassTypeIdentifier = @"pass.com.theanazerka.walleter";

static NSString *WLSHA1(NSData *data) {
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) [hex appendFormat:@"%02x", digest[i]];
    return hex;
}

static NSData *WLPNG(UIImage *image) {
    return UIImagePNGRepresentation(image);
}

@implementation WLPassBuilder

+ (NSData *)pkpassDataForCard:(WLCard *)card error:(NSString **)error {
    NSString *problem = [card validationError];
    if (problem) {
        if (error) *error = problem;
        return nil;
    }

    NSString *message = [card normalizedBarcodeMessage];
    UIColor *bg = card.backgroundColor;
    UIColor *fg = card.foregroundColor;

    NSMutableDictionary *storeCard = [NSMutableDictionary dictionary];
    NSMutableArray *secondary = [NSMutableArray array];
    NSMutableArray *auxiliary = [NSMutableArray array];
    NSMutableArray *back = [NSMutableArray array];

    // длинное содержимое QR (ссылки и т.п.) на лицевой стороне не показываем
    if (message.length <= 24) {
        [secondary addObject:@{ @"key": @"number", @"label": @"НОМЕР КАРТЫ", @"value": message }];
    }
    if (card.holderName.length) {
        [auxiliary addObject:@{ @"key": @"holder", @"label": @"ВЛАДЕЛЕЦ", @"value": card.holderName }];
    }
    [back addObject:@{ @"key": @"backNumber", @"label": @"Номер карты", @"value": message }];
    if (card.holderName.length) {
        [back addObject:@{ @"key": @"backHolder", @"label": @"Владелец", @"value": card.holderName }];
    }
    if (card.notes.length) {
        [back addObject:@{ @"key": @"notes", @"label": @"Заметки", @"value": card.notes }];
    }
    [back addObject:@{ @"key": @"app", @"label": @"Создано", @"value": @"Walleter для iOS 6" }];

    BOOL linear = WLBarcodeFormatIsLinear(card.barcodeFormat);
    if (!linear) {
        // Без картинки-полосы название магазина крупно в primary
        storeCard[@"primaryFields"] = @[ @{ @"key": @"store", @"label": @"СКИДОЧНАЯ КАРТА", @"value": card.storeName } ];
    }
    storeCard[@"secondaryFields"] = secondary;
    storeCard[@"auxiliaryFields"] = auxiliary;
    storeCard[@"backFields"] = back;

    NSMutableDictionary *pass = [@{
        @"formatVersion": @1,
        @"passTypeIdentifier": WLPassTypeIdentifier,
        @"serialNumber": card.identifier,
        @"teamIdentifier": @"WALLETER00",
        @"organizationName": card.storeName,
        @"description": [NSString stringWithFormat:@"Карта %@", card.storeName],
        @"logoText": card.storeName,
        @"backgroundColor": WLColorCSS(bg),
        @"foregroundColor": WLColorCSS(fg),
        @"labelColor": WLColorCSS(fg),
        @"storeCard": storeCard,
    } mutableCopy];

    NSString *nativeFormat = nil;
    switch (card.barcodeFormat) {
        case WLBarcodeFormatQR:     nativeFormat = @"PKBarcodeFormatQR"; break;
        case WLBarcodeFormatPDF417: nativeFormat = @"PKBarcodeFormatPDF417"; break;
        case WLBarcodeFormatAztec:  nativeFormat = @"PKBarcodeFormatAztec"; break;
        default: break;
    }
    if (nativeFormat) {
        pass[@"barcode"] = @{ @"format": nativeFormat, @"message": message, @"messageEncoding": [message canBeConvertedToEncoding:NSISOLatin1StringEncoding] ? @"iso-8859-1" : @"utf-8", @"altText": message };
    }

    NSError *jsonError = nil;
    NSData *passJSON = [NSJSONSerialization dataWithJSONObject:pass options:0 error:&jsonError];
    if (!passJSON) {
        if (error) *error = [NSString stringWithFormat:@"Не удалось собрать pass.json: %@", jsonError.localizedDescription];
        return nil;
    }

    NSMutableDictionary *files = [NSMutableDictionary dictionary];
    files[@"pass.json"] = passJSON;
    files[@"icon.png"] = WLPNG([card iconWithSide:29 scale:1]);
    files[@"icon@2x.png"] = WLPNG([card iconWithSide:29 scale:2]);

    // Логотип слева сверху: свой — вписываем в 160x30, иначе квадратный значок магазина
    UIImage *custom = [card customLogo];
    for (NSNumber *scale in @[ @1, @2 ]) {
        UIImage *logo = custom ? WLFitImage(custom, CGSizeMake(160, 30), scale.floatValue)
                               : [card iconWithSide:30 scale:scale.floatValue];
        files[scale.intValue == 2 ? @"logo@2x.png" : @"logo.png"] = WLPNG(logo);
    }

    if (linear) {
        NSString *modules = nil;
        switch (card.barcodeFormat) {
            case WLBarcodeFormatEAN13: modules = [WLBarcodeRenderer ean13Modules:message]; break;
            case WLBarcodeFormatEAN8:  modules = [WLBarcodeRenderer ean8Modules:message]; break;
            default:                   modules = [WLBarcodeRenderer code128Modules:message]; break;
        }
        if (!modules) {
            if (error) *error = @"Не удалось закодировать штрихкод.";
            return nil;
        }
        // Полоса store card в iOS 6: 320x123 pt
        CGSize stripSize = CGSizeMake(320, 123);
        for (NSNumber *scale in @[ @1, @2 ]) {
            UIImage *strip = [WLBarcodeRenderer imageWithModules:modules caption:message size:stripSize scale:scale.floatValue];
            NSString *name = scale.intValue == 2 ? @"strip@2x.png" : @"strip.png";
            files[name] = WLPNG(strip);
        }
    }

    NSMutableDictionary *manifest = [NSMutableDictionary dictionary];
    for (NSString *name in files) manifest[name] = WLSHA1(files[name]);
    NSData *manifestJSON = [NSJSONSerialization dataWithJSONObject:manifest options:0 error:NULL];

    WLZipWriter *zip = [[WLZipWriter alloc] init];
    for (NSString *name in [[files allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        [zip addFileNamed:name data:files[name]];
    }
    [zip addFileNamed:@"manifest.json" data:manifestJSON];
    return [zip archiveData];
}

@end
