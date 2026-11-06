#import <UIKit/UIKit.h>
#import "WLCard.h"

/// Собирает пасс и показывает системный экран «Добавить в Passbook».
@interface WLPassbookPresenter : NSObject
+ (void)addCard:(WLCard *)card fromViewController:(UIViewController *)controller;
@end
