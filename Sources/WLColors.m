#import "WLColors.h"

typedef struct { const char *name; unsigned int rgb; BOOL darkText; } WLPaletteEntry;

static const WLPaletteEntry kPalette[] = {
    { "Красный",     0xD32F2F, NO  },
    { "Оранжевый",   0xF57C00, NO  },
    { "Жёлтый",      0xFBC02D, YES },
    { "Зелёный",     0x388E3C, NO  },
    { "Бирюзовый",   0x00897B, NO  },
    { "Голубой",     0x0288D1, NO  },
    { "Синий",       0x283593, NO  },
    { "Фиолетовый",  0x6A1B9A, NO  },
    { "Розовый",     0xD81B60, NO  },
    { "Коричневый",  0x5D4037, NO  },
    { "Серый",       0x607D8B, NO  },
    { "Чёрный",      0x212121, NO  },
    { "Белый",       0xF5F5F5, YES },
};

static NSInteger WLClamp(NSInteger index) {
    NSInteger n = WLColorCount();
    return (index < 0 || index >= n) ? 0 : index;
}

static UIColor *WLColorFromRGB(unsigned int rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                           green:((rgb >> 8) & 0xFF) / 255.0
                            blue:(rgb & 0xFF) / 255.0
                           alpha:1.0];
}

NSInteger WLColorCount(void) {
    return sizeof(kPalette) / sizeof(kPalette[0]);
}

NSString *WLColorName(NSInteger index) {
    return [NSString stringWithUTF8String:kPalette[WLClamp(index)].name];
}

UIColor *WLColorBackground(NSInteger index) {
    return WLColorFromRGB(kPalette[WLClamp(index)].rgb);
}

UIColor *WLColorForeground(NSInteger index) {
    return kPalette[WLClamp(index)].darkText ? WLColorFromRGB(0x212121) : [UIColor whiteColor];
}

NSString *WLColorCSS(UIColor *color) {
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![color getRed:&r green:&g blue:&b alpha:&a]) {
        CGFloat w = 0;
        [color getWhite:&w alpha:&a];
        r = g = b = w;
    }
    return [NSString stringWithFormat:@"rgb(%d, %d, %d)", (int)lround(r * 255), (int)lround(g * 255), (int)lround(b * 255)];
}

UIImage *WLColorSwatch(NSInteger index, CGFloat size) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGRect rect = CGRectInset(CGRectMake(0, 0, size, size), 1, 1);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:size / 5];
    [WLColorBackground(index) setFill];
    [path fill];
    [[UIColor colorWithWhite:0 alpha:0.25] setStroke];
    path.lineWidth = 1;
    [path stroke];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
