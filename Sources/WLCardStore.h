#import <Foundation/Foundation.h>
#import "WLCard.h"

@interface WLCardStore : NSObject
+ (instancetype)sharedStore;
@property (nonatomic, readonly) NSArray *cards;
- (void)saveCard:(WLCard *)card;   // добавляет или обновляет по identifier
- (void)removeCard:(WLCard *)card;
@end
