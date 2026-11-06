#import <UIKit/UIKit.h>

/// Квадратная иконка со скруглением: либо картинка, либо цветной фон с надписью.
UIImage *WLIconImage(CGFloat side, CGFloat scale, UIColor *background, UIColor *foreground, NSString *glyph, UIImage *customImage);

/// Белая скруглённая плашка с картинкой, вписанной с отступом (логотип магазина).
UIImage *WLBadgeImage(UIImage *logo, CGSize size, CGFloat scale, CGFloat cornerRadius);

/// Картинка, вписанная в size без фона (для logo.png в пассе).
UIImage *WLFitImage(UIImage *image, CGSize maxSize, CGFloat scale);
