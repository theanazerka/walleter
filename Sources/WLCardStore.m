#import "WLCardStore.h"

@implementation WLCardStore {
    NSMutableArray *_cards;
}

+ (instancetype)sharedStore {
    static WLCardStore *store;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ store = [[WLCardStore alloc] init]; });
    return store;
}

- (NSString *)storagePath {
    // Приложение из Cydia живёт вне песочницы, поэтому кладём данные в свою папку
    NSString *base = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dir = [base stringByAppendingPathComponent:@"Walleter"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
    return [dir stringByAppendingPathComponent:@"cards.archive"];
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
        [_cards removeObjectAtIndex:idx];
        [self persist];
    }
}

@end
