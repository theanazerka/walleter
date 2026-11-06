#import "WLCardStore.h"
#import <UIKit/UIKit.h>

@implementation WLCardStore {
    NSMutableArray *_cards;
}

+ (instancetype)sharedStore {
    static WLCardStore *store;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ store = [[WLCardStore alloc] init]; });
    return store;
}

+ (NSString *)dataDirectory {
    // Приложение из Cydia живёт вне песочницы, поэтому кладём данные в свою папку
    NSString *base = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dir = [base stringByAppendingPathComponent:@"Walleter"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
    return dir;
}

+ (NSString *)logoPathForIdentifier:(NSString *)identifier {
    NSString *dir = [[self dataDirectory] stringByAppendingPathComponent:@"Logos"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
    return [dir stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:@"png"]];
}

- (NSString *)storagePath {
    return [[WLCardStore dataDirectory] stringByAppendingPathComponent:@"cards.archive"];
}

- (void)setCustomLogo:(UIImage *)image forCard:(WLCard *)card {
    NSString *path = [WLCardStore logoPathForIdentifier:card.identifier];
    if (image) {
        // не храним огромные фото: до 320 точек по большей стороне
        CGSize s = image.size;
        CGFloat k = MIN(1.0, 320.0 / MAX(MAX(s.width, s.height), 1));
        CGSize d = CGSizeMake(floor(s.width * k), floor(s.height * k));
        UIGraphicsBeginImageContextWithOptions(d, NO, 1.0);
        [image drawInRect:CGRectMake(0, 0, d.width, d.height)];
        UIImage *small = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        card.hasCustomLogo = [UIImagePNGRepresentation(small) writeToFile:path atomically:YES];
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        card.hasCustomLogo = NO;
    }
}

- (id)init {
    if ((self = [super init])) {
        NSArray *loaded = nil;
        @try {
            loaded = [NSKeyedUnarchiver unarchiveObjectWithFile:[self storagePath]];
        } @catch (NSException *e) {
            NSLog(@"[Walleter] failed to load cards: %@", e);
        }
        _cards = [loaded isKindOfClass:[NSArray class]] ? [loaded mutableCopy] : [NSMutableArray array];
    }
    return self;
}

- (NSArray *)cards {
    return [_cards copy];
}

- (void)persist {
    if (![NSKeyedArchiver archiveRootObject:_cards toFile:[self storagePath]]) {
        NSLog(@"[Walleter] failed to save cards");
    }
}

- (NSUInteger)indexOfIdentifier:(NSString *)identifier {
    return [_cards indexOfObjectPassingTest:^BOOL(WLCard *c, NSUInteger idx, BOOL *stop) {
        return [c.identifier isEqualToString:identifier];
    }];
}

- (void)saveCard:(WLCard *)card {
    NSUInteger idx = [self indexOfIdentifier:card.identifier];
    if (idx == NSNotFound) {
        [_cards addObject:[card copy]];
    } else {
        [_cards replaceObjectAtIndex:idx withObject:[card copy]];
    }
    [self persist];
}

- (void)removeCard:(WLCard *)card {
    NSUInteger idx = [self indexOfIdentifier:card.identifier];
    if (idx != NSNotFound) {
        [[NSFileManager defaultManager] removeItemAtPath:[WLCardStore logoPathForIdentifier:card.identifier] error:NULL];
        [_cards removeObjectAtIndex:idx];
        [self persist];
    }
}

@end
