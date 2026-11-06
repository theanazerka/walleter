#import <UIKit/UIKit.h>

/// Пресет магазина: название, фирменные цвета и значок (буквы на цветном фоне).
@interface WLBrand : NSObject
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *glyph;
@property (nonatomic, readonly) UIColor *backgroundColor;
@property (nonatomic, readonly) UIColor *foregroundColor;

+ (NSArray *)allBrands;
+ (WLBrand *)brandWithIdentifier:(NSString *)identifier;
- (UIImage *)iconWithSide:(CGFloat)side;
@end
