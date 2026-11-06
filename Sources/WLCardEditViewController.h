#import <UIKit/UIKit.h>
#import "WLCard.h"

@interface WLCardEditViewController : UITableViewController
/// card == nil — новая пустая карта
- (id)initWithCard:(WLCard *)card;
/// isNew == YES — карта ещё не сохранена (например, только что отсканирована)
- (id)initWithCard:(WLCard *)card isNew:(BOOL)isNew;
@end
