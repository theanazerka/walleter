#import <UIKit/UIKit.h>

/// Простой список с галочкой для выбора одного варианта.
@interface WLOptionPickerViewController : UITableViewController
- (id)initWithTitle:(NSString *)title
            options:(NSArray *)options          // NSString
             images:(NSArray *)images           // UIImage или nil
           selected:(NSInteger)selected
             footer:(NSString *)footer
         completion:(void (^)(NSInteger index))completion;
@end
