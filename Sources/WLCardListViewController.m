#import "WLCardListViewController.h"
#import "WLCardEditViewController.h"
#import "WLScannerViewController.h"
#import "WLStorePickerViewController.h"
#import "WLPassbookPresenter.h"
#import "WLCardStore.h"

enum { WLAddScan, WLAddPhoto, WLAddManual };

@interface WLCardListViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation WLCardListViewController {
    UILabel *_emptyLabel;
    NSArray *_addActions;   // NSNumber, по порядку кнопок в action sheet
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Мои карты";
    self.tableView.rowHeight = 60;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTapped)];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    _emptyLabel = [[UILabel alloc] initWithFrame:CGRectInset(self.view.bounds, 30, 0)];
    _emptyLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _emptyLabel.numberOfLines = 0;
    _emptyLabel.textAlignment = NSTextAlignmentCenter;
    _emptyLabel.textColor = [UIColor grayColor];
    _emptyLabel.backgroundColor = [UIColor clearColor];
    _emptyLabel.font = [UIFont systemFontOfSize:17];
    _emptyLabel.text = @"Карт пока нет.\n\nНажмите «+» и отсканируйте штрихкод карты — она сразу попадёт в Passbook.";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self updateEmptyState];
}

- (void)updateEmptyState {
    BOOL empty = [WLCardStore sharedStore].cards.count == 0;
    self.tableView.backgroundView = empty ? _emptyLabel : nil;
    self.tableView.separatorStyle = empty ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine;
    self.navigationItem.leftBarButtonItem.enabled = !empty;
    if (empty && self.editing) [self setEditing:NO animated:NO];
}

- (void)alert:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - Добавление

- (void)addTapped {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    NSMutableArray *actions = [NSMutableArray array];
    if ([WLScannerViewController isCameraAvailable]) {
        [sheet addButtonWithTitle:@"Сканировать камерой"];
        [actions addObject:@(WLAddScan)];
    }
    [sheet addButtonWithTitle:@"Распознать с фото / скриншота"];
    [actions addObject:@(WLAddPhoto)];
    [sheet addButtonWithTitle:@"Ввести вручную"];
    [actions addObject:@(WLAddManual)];
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Отмена"];
    _addActions = actions;
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex || buttonIndex < 0 || buttonIndex >= (NSInteger)_addActions.count) return;
    switch ([_addActions[buttonIndex] integerValue]) {
        case WLAddScan:   [self startScan]; break;
        case WLAddPhoto:  [self pickPhoto]; break;
        case WLAddManual: [self openEditorForCard:nil]; break;
    }
}

- (void)openEditorForCard:(WLCard *)card {
    WLCardEditViewController *edit = [[WLCardEditViewController alloc] initWithCard:card];
    [self.navigationController pushViewController:edit animated:YES];
}

- (void)startScan {
    __weak WLCardListViewController *weakSelf = self;
    WLScannerViewController *scanner = [[WLScannerViewController alloc] initWithCompletion:^(WLScanResult *result) {
        WLCardListViewController *me = weakSelf;
        [me dismissViewControllerAnimated:YES completion:^{
            if (result) [me handleScanResult:result];
        }];
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:scanner];
    nav.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)pickPhoto {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [self alert:@"Нет доступа к фото" message:nil];
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    if (!image) return;

    self.navigationItem.rightBarButtonItem.enabled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        WLScanResult *result = [[[WLBarcodeDecoder alloc] init] decodeImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.rightBarButtonItem.enabled = YES;
            if (result) {
                [self handleScanResult:result];
            } else {
                [self alert:@"Штрихкод не найден" message:@"Попробуйте более чёткое фото или скриншот, где код целиком в кадре."];
            }
        });
    });
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/// Нашли код → спрашиваем магазин → сохраняем → сразу в Passbook
- (void)handleScanResult:(WLScanResult *)result {
    NSString *prompt = [NSString stringWithFormat:@"%@: %@", WLBarcodeFormatName(result.format), result.text];
    __weak WLCardListViewController *weakSelf = self;
    WLStorePickerViewController *picker = [[WLStorePickerViewController alloc] initWithPrompt:prompt selected:nil completion:^(WLBrand *brand) {
        WLCardListViewController *me = weakSelf;
        if (!me) return;
        WLCard *card = [WLCard newCard];
        card.cardNumber = result.text;
        card.barcodeFormat = result.format;
        if (!brand) {
            // Другой магазин — открываем форму, чтобы вписать название
            WLCardEditViewController *edit = [[WLCardEditViewController alloc] initWithCard:card isNew:YES];
            NSMutableArray *stack = [me.navigationController.viewControllers mutableCopy];
            [stack removeLastObject];
            [stack addObject:edit];
            [me.navigationController setViewControllers:stack animated:YES];
            return;
        }
        card.brandId = brand.identifier;
        card.storeName = brand.name;
        card.colorIndex = -1;
        [[WLCardStore sharedStore] saveCard:card];
        [me.navigationController popToViewController:me animated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [WLPassbookPresenter addCard:card fromViewController:me.navigationController];
        });
    }];
    picker.title = @"Чья карта?";
    [self.navigationController pushViewController:picker animated:YES];
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [WLCardStore sharedStore].cards.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"card"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"card"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    WLCard *card = [WLCardStore sharedStore].cards[indexPath.row];
    cell.textLabel.text = card.storeName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", card.cardNumber, WLBarcodeFormatName(card.barcodeFormat)];
    cell.imageView.image = [card iconWithSide:40 scale:0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self openEditorForCard:[WLCardStore sharedStore].cards[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    WLCard *card = [WLCardStore sharedStore].cards[indexPath.row];
    [[WLCardStore sharedStore] removeCard:card];
    [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateEmptyState];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Удалить";
}

@end
