#import <UIKit/UIKit.h>

/// Пресет магазина: название, фирменные цвета, логотип (если есть) или буквенный значок.
@interface WLBrand : NSObject
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *glyph;
@property (nonatomic, readonly) UIColor *backgroundColor;
@property (nonatomic, readonly) UIColor *foregroundColor;

/// Настоящий логотип из Resources/Brands/<id>.png (nil, если файла нет)
@property (nonatomic, readonly) UIImage *logo;

+ (NSArray *)allBrands;
+ (WLBrand *)brandWithIdentifier:(NSString *)identifier;
- (UIImage *)iconWithSide:(CGFloat)side;
- (UIImage *)iconWithSide:(CGFloat)side scale:(CGFloat)scale;
@end
