#import "WLBrand.h"
#import "WLIcon.h"

typedef struct { const char *ident, *name, *glyph; unsigned int bg, fg; } WLBrandEntry;

// Цвета подобраны «по памяти» под фирменные; логотипы не используются — только буквы.
static const WLBrandEntry kBrands[] = {
    { "pyaterochka", "Пятёрочка",       "5",   0xE31E24, 0xFFFFFF },
    { "magnit",      "Магнит",          "М",   0xD6001C, 0xFFFFFF },
    { "perekrestok", "Перекрёсток",     "П",   0x0B6E37, 0xFFFFFF },
    { "dixy",        "Дикси",           "Д",   0xF28C00, 0xFFFFFF },
    { "lenta",       "Лента",           "Л",   0x003F8A, 0xFFD400 },
    { "kb",          "Красное&Белое",   "К&Б", 0xB5121B, 0xFFFFFF },
    { "bristol",     "Бристоль",        "Б",   0x1D2B64, 0xFFFFFF },
    { "vkusvill",    "ВкусВилл",        "ВВ",  0x2EA836, 0xFFFFFF },
    { "auchan",      "Ашан",            "А",   0xE2001A, 0xFFFFFF },
    { "okey",        "О'КЕЙ",           "ОК",  0x231F20, 0xE31E24 },
    { "metro",       "METRO",           "M",   0x002D72, 0xFFE500 },
    { "globus",      "Глобус",          "Г",   0xFFD200, 0xE30613 },
    { "azbuka",      "Азбука вкуса",    "АВ",  0x0F4B2F, 0xE6C27A },
    { "verny",       "Верный",          "В",   0xE4002B, 0xFFFFFF },
    { "spar",        "SPAR",            "S",   0x00843D, 0xFFFFFF },
    { "fixprice",    "Fix Price",       "FP",  0x0072BC, 0xFFE600 },
    { "svetofor",    "Светофор",        "С",   0x1A1A1A, 0xFFC400 },
    { "sportmaster", "Спортмастер",     "СМ",  0x0057A6, 0xFFFFFF },
    { "letual",      "Л'Этуаль",        "Л'",  0x000000, 0xFFFFFF },
    { "goldapple",   "Золотое Яблоко",  "ЗЯ",  0x111111, 0xD4AF37 },
    { "ulybka",      "Улыбка радуги",   "УР",  0xE6007E, 0xFFFFFF },
    { "mvideo",      "М.Видео",         "МВ",  0xE30613, 0xFFFFFF },
    { "dns",         "DNS",             "DNS", 0xF68B1F, 0xFFFFFF },
    { "detmir",      "Детский мир",     "ДМ",  0x1E5AA8, 0xFFFFFF },
    { "lemana",      "Лемана ПРО",      "ЛП",  0x6CB33F, 0xFFFFFF },
    { "rigla",       "Ригла",           "Р",   0x00A651, 0xFFFFFF },
    { "gloria",      "Gloria Jeans",    "GJ",  0x1C1C1C, 0xFFFFFF },
};

static UIColor *WLRGB(unsigned int rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0 green:((rgb >> 8) & 0xFF) / 255.0 blue:(rgb & 0xFF) / 255.0 alpha:1];
}

@implementation WLBrand

- (id)initWithEntry:(const WLBrandEntry *)e {
    if ((self = [super init])) {
        _identifier = @(e->ident);
        _name = @(e->name);
        _glyph = @(e->glyph);
        _backgroundColor = WLRGB(e->bg);
        _foregroundColor = WLRGB(e->fg);
    }
    return self;
}

+ (NSArray *)allBrands {
    static NSArray *brands;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableArray *list = [NSMutableArray array];
        for (size_t i = 0; i < sizeof(kBrands) / sizeof(kBrands[0]); i++) {
            [list addObject:[[WLBrand alloc] initWithEntry:&kBrands[i]]];
        }
        brands = [list copy];
    });
    return brands;
}

+ (WLBrand *)brandWithIdentifier:(NSString *)identifier {
    if (!identifier.length) return nil;
    for (WLBrand *b in [self allBrands]) {
        if ([b.identifier isEqualToString:identifier]) return b;
    }
    return nil;
}

- (UIImage *)iconWithSide:(CGFloat)side {
    return WLIconImage(side, 0, self.backgroundColor, self.foregroundColor, self.glyph, nil);
}

@end
