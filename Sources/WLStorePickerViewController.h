#import <UIKit/UIKit.h>
#import "WLBrand.h"

/// Список магазинов-пресетов. brand == nil — «Другой магазин».
@interface WLStorePickerViewController : UITableViewController
- (id)initWithPrompt:(NSString *)prompt
            selected:(NSString *)selectedBrandId
          completion:(void (^)(WLBrand *brand))completion;
@end
