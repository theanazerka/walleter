#import <UIKit/UIKit.h>
#import "WLCard.h"

@interface WLCardStore : NSObject
+ (instancetype)sharedStore;
+ (NSString *)logoPathForIdentifier:(NSString *)identifier;
/// Сохраняет (image != nil) или удаляет свой логотип карты и обновляет card.hasCustomLogo
- (void)setCustomLogo:(UIImage *)image forCard:(WLCard *)card;
@property (nonatomic, readonly) NSArray *cards;
- (void)saveCard:(WLCard *)card;   // добавляет или обновляет по identifier
- (void)removeCard:(WLCard *)card;
@end
