#import <UIKit/UIKit.h>
#import "WLCard.h"

@interface WLCardEditViewController : UITableViewController
/// card == nil — новая карта
- (id)initWithCard:(WLCard *)card;
@end
