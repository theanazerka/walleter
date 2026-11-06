#import "WLPassbookPresenter.h"
#import "WLPassBuilder.h"
#import <PassKit/PassKit.h>

@interface WLPassbookPresenter () <PKAddPassesViewControllerDelegate>
@end

@implementation WLPassbookPresenter

+ (instancetype)shared {
    static WLPassbookPresenter *p;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ p = [[WLPassbookPresenter alloc] init]; });
    return p;
}

+ (void)alert:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

+ (void)addCard:(WLCard *)card fromViewController:(UIViewController *)controller {
    if (NSClassFromString(@"PKPassLibrary") == nil || ![PKPassLibrary isPassLibraryAvailable]) {
        [self alert:@"Passbook недоступен" message:@"На этом устройстве нет Passbook (например, на iPad в iOS 6)."];
        return;
    }

    NSString *buildError = nil;
    NSData *data = [WLPassBuilder pkpassDataForCard:card error:&buildError];
    if (!data) {
        [self alert:@"Не получилось" message:buildError];
        return;
    }

    NSError *passError = nil;
    PKPass *pass = [[PKPass alloc] initWithData:data error:&passError];
    if (!pass) {
        NSString *msg = [NSString stringWithFormat:@"Passbook отклонил карту%@.\n\nУбедитесь, что установлен твик SigPass, и сделайте respring.",
                         passError ? [NSString stringWithFormat:@" (%@)", passError.localizedDescription] : @""];
        [self alert:@"Ошибка Passbook" message:msg];
        return;
    }

    PKAddPassesViewController *add = [[PKAddPassesViewController alloc] initWithPass:pass];
    if (!add) {
        [self alert:@"Ошибка Passbook" message:@"Не удалось открыть экран добавления карты."];
        return;
    }
    add.delegate = [self shared];
    [controller presentViewController:add animated:YES completion:nil];
}

- (void)addPassesViewControllerDidFinish:(PKAddPassesViewController *)controller {
    [controller.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
