#import "WLBarcodeRenderer.h"

static const char *kEANL[10] = { "0001101","0011001","0010011","0111101","0100011","0110001","0101111","0111011","0110111","0001011" };
static const char *kEANG[10] = { "0100111","0110011","0011011","0100001","0011101","0111001","0000101","0010001","0001001","0010111" };
static const char *kEANR[10] = { "1110010","1100110","1101100","1000010","1011100","1001110","1010000","1000100","1001000","1110100" };
static const char *kEANParity[10] = { "LLLLLL","LLGLGG","LLGGLG","LLGGGL","LGLLGG","LGGLLG","LGGGLG","LGGGGL","LGLGLG","LGLGGL" };

// Ширины полос/пробелов для значений 0..106 (106 — STOP)
static const char *kCode128[107] = {
    "212222","222122","222221","121223","121322","131222","122213","122312","132212","221213",
    "221312","231212","112232","122132","122231","113222","123122","123221","223211","221132",
    "221231","213212","223112","312131","311222","321122","321221","312212","322112","322211",
    "212123","212321","232121","111323","131123","131321","112313","132113","132311","211313",
    "231113","231311","112133","112331","132131","113123","113321","133121","313121","211331",
    "231131","213113","213311","213131","311123","311321","331121","312113","312311","332111",
    "314111","221411","431111","111224","111422","121124","121421","141122","141221","112214",
    "112412","122114","122411","142112","142211","241211","221114","413111","241112","134111",
    "111242","121142","121241","114212","124112","124211","411212","421112","421211","212141",
    "214121","412121","111143","111341","131141","114113","114311","411113","411311","113141",
    "114131","311141","411131","211412","211214","211232","2331112"
};

enum { kCode128StartB = 104, kCode128StartC = 105, kCode128CodeB = 100, kCode128CodeC = 99, kCode128Stop = 106 };

static BOOL WLIsDigits(NSString *s) {
    if (s.length == 0) return NO;
    for (NSUInteger i = 0; i < s.length; i++) {
        unichar c = [s characterAtIndex:i];
        if (c < '0' || c > '9') return NO;
    }
    return YES;
}

static int WLEANCheckDigit(NSString *twelve) {
    int sum = 0;
    for (NSUInteger i = 0; i < 12; i++) {
        int d = [twelve characterAtIndex:i] - '0';
        sum += (i % 2 == 0) ? d : d * 3;
    }
    return (10 - sum % 10) % 10;
}

static int WLEAN8CheckDigit(NSString *seven) {
    int sum = 0;
    for (NSUInteger i = 0; i < 7; i++) {
        int d = [seven characterAtIndex:i] - '0';
        sum += (i % 2 == 0) ? d * 3 : d;
    }
    return (10 - sum % 10) % 10;
}

static NSString *WLStripSpaces(NSString *s) {
    return [[s componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
}

@implementation WLBarcodeRenderer

+ (NSString *)ean13ValidationError:(NSString *)number {
    NSString *n = WLStripSpaces(number);
    if (!WLIsDigits(n) || (n.length != 12 && n.length != 13)) {
        return @"EAN-13 — это 13 цифр (или 12 без контрольной). Если на карте другой код, выберите Code 128.";
    }
    if (n.length == 13 && WLEANCheckDigit(n) != [n characterAtIndex:12] - '0') {
        return [NSString stringWithFormat:@"Контрольная цифра EAN-13 не сходится (ожидается %d). Проверьте номер или выберите Code 128.", WLEANCheckDigit(n)];
    }
    return nil;
}

+ (NSString *)ean13FullNumber:(NSString *)number {
    NSString *n = WLStripSpaces(number);
    if ([self ean13ValidationError:n]) return nil;
    if (n.length == 12) n = [n stringByAppendingFormat:@"%d", WLEANCheckDigit(n)];
    return n;
}

+ (NSString *)ean8ValidationError:(NSString *)number {
    NSString *n = WLStripSpaces(number);
    if (!WLIsDigits(n) || (n.length != 7 && n.length != 8)) {
        return @"EAN-8 — это 8 цифр (или 7 без контрольной).";
    }
    if (n.length == 8 && WLEAN8CheckDigit(n) != [n characterAtIndex:7] - '0') {
        return [NSString stringWithFormat:@"Контрольная цифра EAN-8 не сходится (ожидается %d).", WLEAN8CheckDigit(n)];
    }
    return nil;
}

+ (NSString *)ean8FullNumber:(NSString *)number {
    NSString *n = WLStripSpaces(number);
    if ([self ean8ValidationError:n]) return nil;
    if (n.length == 7) n = [n stringByAppendingFormat:@"%d", WLEAN8CheckDigit(n)];
    return n;
}

+ (NSString *)code128ValidationError:(NSString *)text {
    if (text.length == 0) return @"Пустой номер.";
    if (text.length > 48) return @"Слишком длинный номер для Code 128 (максимум 48 символов).";
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        if (c < 32 || c > 126) return @"Code 128 поддерживает только латиницу, цифры и обычные символы.";
    }
    return nil;
}

+ (NSString *)ean13Modules:(NSString *)number {
    NSString *n = [self ean13FullNumber:number];
    if (!n) return nil;
    NSMutableString *m = [NSMutableString stringWithString:@"101"];
    const char *parity = kEANParity[[n characterAtIndex:0] - '0'];
    for (int i = 1; i <= 6; i++) {
        int d = [n characterAtIndex:i] - '0';
        [m appendString:@(parity[i - 1] == 'L' ? kEANL[d] : kEANG[d])];
    }
    [m appendString:@"01010"];
    for (int i = 7; i <= 12; i++) {
        [m appendString:@(kEANR[[n characterAtIndex:i] - '0'])];
    }
    [m appendString:@"101"];
    return m;
}

+ (NSString *)ean8Modules:(NSString *)number {
    NSString *n = [self ean8FullNumber:number];
    if (!n) return nil;
    NSMutableString *m = [NSMutableString stringWithString:@"101"];
    for (int i = 0; i < 4; i++) [m appendString:@(kEANL[[n characterAtIndex:i] - '0'])];
    [m appendString:@"01010"];
    for (int i = 4; i < 8; i++) [m appendString:@(kEANR[[n characterAtIndex:i] - '0'])];
    [m appendString:@"101"];
    return m;
}

static void WLAppendCode128(NSMutableString *m, int value) {
    const char *w = kCode128[value];
    BOOL bar = YES;
    for (const char *p = w; *p; p++) {
        for (int k = 0; k < *p - '0'; k++) [m appendString:bar ? @"1" : @"0"];
        bar = !bar;
    }
}

/// Сколько цифр подряд начиная с позиции
static NSUInteger WLDigitRun(NSString *s, NSUInteger from) {
    NSUInteger i = from;
    while (i < s.length && [s characterAtIndex:i] >= '0' && [s characterAtIndex:i] <= '9') i++;
    return i - from;
}

+ (NSString *)code128Modules:(NSString *)text {
    if ([self code128ValidationError:text]) return nil;

    NSMutableArray *values = [NSMutableArray array];
    NSUInteger i = 0;
    BOOL setC;
    NSUInteger run = WLDigitRun(text, 0);
    // Набор C (пары цифр) выгоден, если в начале >= 4 цифр или вся строка — чётное число цифр
    if ((run == text.length && run % 2 == 0 && run >= 2) || run >= 4) {
        setC = YES;
        [values addObject:@(kCode128StartC)];
    } else {
        setC = NO;
        [values addObject:@(kCode128StartB)];
    }

    while (i < text.length) {
        run = WLDigitRun(text, i);
        if (setC) {
            if (run >= 2) {
                int pair = ([text characterAtIndex:i] - '0') * 10 + ([text characterAtIndex:i + 1] - '0');
                [values addObject:@(pair)];
                i += 2;
                continue;
            }
            [values addObject:@(kCode128CodeB)];
            setC = NO;
        }
        // набор B
        BOOL atEnd = (i + run == text.length);
        if (run >= 6 || (atEnd && run >= 4)) {
            if (run % 2 == 1) { // нечётную цифру отдаём набору B
                [values addObject:@([text characterAtIndex:i] - 32)];
                i++;
            }
            [values addObject:@(kCode128CodeC)];
            setC = YES;
            continue;
        }
        [values addObject:@([text characterAtIndex:i] - 32)];
        i++;
    }

    NSInteger checksum = [values[0] integerValue];
    for (NSUInteger k = 1; k < values.count; k++) checksum += [values[k] integerValue] * (NSInteger)k;
    [values addObject:@(checksum % 103)];
    [values addObject:@(kCode128Stop)];

    NSMutableString *m = [NSMutableString string];
    for (NSNumber *v in values) WLAppendCode128(m, v.intValue);
    return m;
}

+ (UIImage *)imageWithModules:(NSString *)modules caption:(NSString *)caption size:(CGSize)size scale:(CGFloat)scale {
    if (modules.length == 0) return nil;

    CGFloat pxWidth = size.width * scale, pxHeight = size.height * scale;
    CGFloat quiet = 10;                                    // минимальная тихая зона в модулях
    NSInteger modulePx = (NSInteger)floor(pxWidth / (modules.length + 2 * quiet));
    if (modulePx < 1) modulePx = 1;
    CGFloat barcodeWidthPx = modulePx * (CGFloat)modules.length;
    CGFloat x0 = floor((pxWidth - barcodeWidthPx) / 2);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(pxWidth, pxHeight), YES, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    CGContextSetShouldAntialias(ctx, NO);

    [[UIColor whiteColor] setFill];
    CGContextFillRect(ctx, CGRectMake(0, 0, pxWidth, pxHeight));

    CGFloat captionHeight = caption.length ? floor(pxHeight * 0.20) : 0;
    CGFloat top = floor(pxHeight * 0.10);
    CGFloat barHeight = pxHeight - top - captionHeight - floor(pxHeight * 0.06);

    [[UIColor blackColor] setFill];
    for (NSUInteger i = 0; i < modules.length; i++) {
        if ([modules characterAtIndex:i] == '1') {
            CGContextFillRect(ctx, CGRectMake(x0 + i * modulePx, top, modulePx, barHeight));
        }
    }

    if (caption.length) {
        CGContextSetShouldAntialias(ctx, YES);
        UIFont *font = [UIFont fontWithName:@"Courier-Bold" size:captionHeight * 0.8] ?: [UIFont boldSystemFontOfSize:captionHeight * 0.8];
        CGRect textRect = CGRectMake(0, top + barHeight + 2, pxWidth, captionHeight);
        [caption drawInRect:textRect withFont:font lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
    }

    CGImageRef cg = UIGraphicsGetImageFromCurrentImageContext().CGImage;
    UIImage *image = [UIImage imageWithCGImage:cg scale:scale orientation:UIImageOrientationUp];
    UIGraphicsEndImageContext();
    return image;
}

@end
