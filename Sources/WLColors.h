#import <UIKit/UIKit.h>

NSInteger WLColorCount(void);
NSString *WLColorName(NSInteger index);
UIColor *WLColorBackground(NSInteger index);
UIColor *WLColorForeground(NSInteger index);
/// "rgb(r, g, b)" для pass.json
NSString *WLColorCSS(UIColor *color);
UIImage *WLColorSwatch(NSInteger index, CGFloat size);
