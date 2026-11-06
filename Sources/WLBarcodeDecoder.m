#import "WLBarcodeDecoder.h"
#import "WLBarcodeRenderer.h"
#include <zbar.h>

@implementation WLScanResult
- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@", self.symbologyName, self.text];
}
@end

@implementation WLBarcodeDecoder {
    zbar_image_scanner_t *_scanner;
    NSMutableData *_buffer;
}

- (id)init {
    if ((self = [super init])) {
        _scanner = zbar_image_scanner_create();
        zbar_image_scanner_set_config(_scanner, 0, ZBAR_CFG_ENABLE, 1);
        // UPC-A отдаём как EAN-13 (с ведущим нулём) — так проще печатать
        zbar_image_scanner_set_config(_scanner, ZBAR_UPCA, ZBAR_CFG_ENABLE, 0);
        _buffer = [NSMutableData data];
    }
    return self;
}

- (void)dealloc {
    if (_scanner) zbar_image_scanner_destroy(_scanner);
}

static NSString *WLStringFromBytes(const char *bytes, unsigned int length) {
    if (!bytes || !length) return nil;
    NSString *s = [[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding];
    if (!s) s = [[NSString alloc] initWithBytes:bytes length:length encoding:NSISOLatin1StringEncoding];
    return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static BOOL WLIsPrintableASCII(NSString *s) {
    for (NSUInteger i = 0; i < s.length; i++) {
        unichar c = [s characterAtIndex:i];
        if (c < 32 || c > 126) return NO;
    }
    return s.length > 0;
}

- (WLScanResult *)resultForSymbol:(const zbar_symbol_t *)sym {
    zbar_symbol_type_t type = zbar_symbol_get_type(sym);
    NSString *text = WLStringFromBytes(zbar_symbol_get_data(sym), zbar_symbol_get_data_length(sym));
    if (!text.length) return nil;

    WLScanResult *r = [[WLScanResult alloc] init];
    r.symbologyName = @(zbar_get_symbol_name(type));
    r.text = text;
    switch (type) {
        case ZBAR_EAN13:
        case ZBAR_ISBN13:
            r.format = WLBarcodeFormatEAN13;
            break;
        case ZBAR_UPCA:
            r.format = WLBarcodeFormatEAN13;
            if (text.length == 12) r.text = [@"0" stringByAppendingString:text];
            break;
        case ZBAR_EAN8:
            r.format = WLBarcodeFormatEAN8;
            break;
        case ZBAR_QRCODE:
            r.format = WLBarcodeFormatQR;
            break;
        default:
            // Code 128 / 39 / 93, I2of5, DataBar, Codabar, UPC-E — перекодируем в Code 128
            r.format = (WLIsPrintableASCII(text) && text.length <= 48) ? WLBarcodeFormatCode128 : WLBarcodeFormatQR;
            break;
    }
    // если номер вдруг не проходит проверку EAN — лучше Code 128, чем ошибка
    if (r.format == WLBarcodeFormatEAN13 && [WLBarcodeRenderer ean13ValidationError:r.text]) r.format = WLBarcodeFormatCode128;
    if (r.format == WLBarcodeFormatEAN8 && [WLBarcodeRenderer ean8ValidationError:r.text]) r.format = WLBarcodeFormatCode128;
    return r;
}

- (WLScanResult *)decodeGray:(const uint8_t *)pixels width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow {
    if (!pixels || width == 0 || height == 0) return nil;

    const uint8_t *data = pixels;
    if (bytesPerRow != width) {
        [_buffer setLength:width * height];
        uint8_t *dst = _buffer.mutableBytes;
        for (size_t y = 0; y < height; y++) memcpy(dst + y * width, pixels + y * bytesPerRow, width);
        data = dst;
    }

    zbar_image_t *img = zbar_image_create();
    zbar_image_set_format(img, zbar_fourcc('Y', '8', '0', '0'));
    zbar_image_set_size(img, (unsigned)width, (unsigned)height);
    zbar_image_set_data(img, data, (unsigned long)(width * height), NULL);

    WLScanResult *best = nil;
    if (zbar_scan_image(_scanner, img) > 0) {
        for (const zbar_symbol_t *sym = zbar_image_first_symbol(img); sym; sym = zbar_symbol_next(sym)) {
            WLScanResult *r = [self resultForSymbol:sym];
            if (!r) continue;
            // QR обычно надёжнее; иначе берём первый
            if (!best || r.format == WLBarcodeFormatQR) best = r;
        }
    }
    zbar_image_destroy(img);
    return best;
}

- (WLScanResult *)decodeCGImage:(CGImageRef)cg maxSide:(CGFloat)maxSide {
    size_t w = CGImageGetWidth(cg), h = CGImageGetHeight(cg);
    CGFloat k = MIN(1.0, maxSide / (CGFloat)MAX(w, h));
    size_t W = (size_t)MAX(1, floor(w * k)), H = (size_t)MAX(1, floor(h * k));

    NSMutableData *gray = [NSMutableData dataWithLength:W * H];
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef ctx = CGBitmapContextCreate(gray.mutableBytes, W, H, 8, W, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CGColorSpaceRelease(cs);
    if (!ctx) return nil;
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, W, H));
    CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);
    CGContextDrawImage(ctx, CGRectMake(0, 0, W, H), cg);
    CGContextRelease(ctx);
    return [self decodeGray:gray.bytes width:W height:H bytesPerRow:W];
}

- (WLScanResult *)decodeImage:(UIImage *)image {
    CGImageRef cg = image.CGImage;
    if (!cg) return nil;
    // Ориентация не важна: ZBar ищет и по горизонтали, и по вертикали
    WLScanResult *r = [self decodeCGImage:cg maxSide:1600];
    if (!r) r = [self decodeCGImage:cg maxSide:800];
    return r;
}

@end
