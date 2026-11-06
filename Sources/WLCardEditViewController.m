#import "WLCardEditViewController.h"
#import "WLOptionPickerViewController.h"
#import "WLStorePickerViewController.h"
#import "WLScannerViewController.h"
#import "WLPassbookPresenter.h"
#import "WLCardStore.h"
#import "WLBrand.h"
#import "WLColors.h"
#import "WLIcon.h"

enum { WLSectionCard, WLSectionBarcode, WLSectionLook, WLSectionNotes, WLSectionActions, WLSectionCount };
enum { WLRowBrand, WLRowStoreName, WLRowNumber, WLRowHolder };
enum { WLRowFormat, WLRowScan, WLRowPhotoScan };
enum { WLRowColor, WLRowLogo };
enum { WLFieldStore = 1, WLFieldNumber, WLFieldHolder, WLFieldNotes };
enum { WLSheetDelete = 100, WLSheetLogo };
enum { WLPickBarcode, WLPickLogo };

@interface WLCardEditViewController () <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation WLCardEditViewController {
    WLCard *_card;
    BOOL _isNew;
    BOOL _hasCamera;
    NSInteger _pickPurpose;
    NSMutableDictionary *_fieldCells;   // tag -> UITableViewCell
}

- (id)initWithCard:(WLCard *)card {
    return [self initWithCard:card isNew:(card == nil)];
}

- (id)initWithCard:(WLCard *)card isNew:(BOOL)isNew {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        _isNew = isNew;
        _card = card ? [card copy] : [WLCard newCard];
        _fieldCells = [NSMutableDictionary dictionary];
        _hasCamera = [WLScannerViewController isCameraAvailable];
        self.title = _isNew ? @"Новая карта" : _card.storeName;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Сохранить" style:UIBarButtonItemStyleDone target:self action:@selector(saveTapped)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self syncFields];
    [self.tableView reloadData];
}

- (void)alert:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - Поля ввода

- (UITextField *)textFieldWithTag:(NSInteger)tag {
    return (UITextField *)[[self fieldCellForTag:tag] viewWithTag:tag];
}

- (void)syncFields {
    [self textFieldWithTag:WLFieldStore].text = _card.storeName;
    [self textFieldWithTag:WLFieldNumber].text = _card.cardNumber;
    [self textFieldWithTag:WLFieldHolder].text = _card.holderName;
    [self textFieldWithTag:WLFieldNotes].text = _card.notes;
}

- (UITableViewCell *)fieldCellForTag:(NSInteger)tag {
    UITableViewCell *cell = _fieldCells[@(tag)];
    if (cell) return cell;

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15];

    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(110, 11, 180, 24)];
    field.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    field.tag = tag;
    field.delegate = self;
    field.font = [UIFont systemFontOfSize:16];
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.returnKeyType = UIReturnKeyNext;
    field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [field addTarget:self action:@selector(fieldChanged:) forControlEvents:UIControlEventEditingChanged];

    switch (tag) {
        case WLFieldStore:
            cell.textLabel.text = @"Название";
            field.placeholder = @"Как подписать карту";
            field.autocapitalizationType = UITextAutocapitalizationTypeWords;
            break;
        case WLFieldNumber:
            cell.textLabel.text = @"Номер";
            field.placeholder = @"Цифры под штрихкодом";
            field.autocorrectionType = UITextAutocorrectionTypeNo;
            field.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            field.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            break;
        case WLFieldHolder:
            cell.textLabel.text = @"Владелец";
            field.placeholder = @"Необязательно";
            field.autocapitalizationType = UITextAutocapitalizationTypeWords;
            break;
        case WLFieldNotes:
            cell.textLabel.text = @"Заметка";
            field.placeholder = @"Скидка 5%, PIN и т.п.";
            field.returnKeyType = UIReturnKeyDone;
            break;
    }
    [cell.contentView addSubview:field];
    _fieldCells[@(tag)] = cell;
    return cell;
}

- (void)fieldChanged:(UITextField *)field {
    NSString *text = field.text ?: @"";
    switch (field.tag) {
        case WLFieldStore:  _card.storeName = text; break;
        case WLFieldNumber: _card.cardNumber = text; break;
        case WLFieldHolder: _card.holderName = text; break;
        case WLFieldNotes:  _card.notes = text; break;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.tag < WLFieldNotes) {
        [[self textFieldWithTag:textField.tag + 1] becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

#pragma mark - Таблица

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return WLSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case WLSectionCard:    return 4;
        case WLSectionBarcode: return 3;
        case WLSectionLook:    return 2;
        case WLSectionActions: return _isNew ? 1 : 2;
        default:               return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case WLSectionCard:    return @"Карта";
        case WLSectionBarcode: return @"Штрихкод";
        case WLSectionLook:    return @"Оформление";
        default:               return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == WLSectionBarcode && WLBarcodeFormatIsLinear(_card.barcodeFormat)) {
        return @"Passbook в iOS 6 не умеет линейные штрихкоды, поэтому Walleter нарисует его картинкой на карте.";
    }
    if (section == WLSectionActions) return @"Для добавления в Passbook нужен твик SigPass.";
    return nil;
}

- (UITableViewCell *)valueCell:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"value"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"value"];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;
    cell.detailTextLabel.text = nil;
    return cell;
}

- (UITableViewCell *)buttonCell:(UITableView *)tableView title:(NSString *)title color:(UIColor *)color {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"action"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"action"];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
    }
    cell.textLabel.text = title;
    cell.textLabel.textColor = color;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIColor *blue = [UIColor colorWithRed:0.10 green:0.40 blue:0.80 alpha:1];
    switch (indexPath.section) {
        case WLSectionCard: {
            if (indexPath.row == WLRowBrand) {
                UITableViewCell *cell = [self valueCell:tableView];
                cell.textLabel.text = @"Магазин";
                cell.detailTextLabel.text = _card.brand ? _card.brand.name : @"Другой";
                cell.imageView.image = [_card iconWithSide:30 scale:0];
                return cell;
            }
            return [self fieldCellForTag:WLFieldStore + (indexPath.row - WLRowStoreName)];
        }
        case WLSectionNotes:
            return [self fieldCellForTag:WLFieldNotes];
        case WLSectionBarcode: {
            if (indexPath.row == WLRowFormat) {
                UITableViewCell *cell = [self valueCell:tableView];
                cell.textLabel.text = @"Тип";
                cell.detailTextLabel.text = WLBarcodeFormatName(_card.barcodeFormat);
                return cell;
            }
            if (indexPath.row == WLRowScan) {
                return [self buttonCell:tableView title:@"Сканировать камерой" color:_hasCamera ? blue : [UIColor grayColor]];
            }
            return [self buttonCell:tableView title:@"Распознать с фото" color:blue];
        }
        case WLSectionLook: {
            UITableViewCell *cell = [self valueCell:tableView];
            if (indexPath.row == WLRowColor) {
                cell.textLabel.text = @"Цвет";
                cell.detailTextLabel.text = _card.usesBrandColors ? @"Фирменный" : WLColorName(MAX(_card.colorIndex, 0));
                cell.imageView.image = WLIconImage(28, 0, _card.backgroundColor, _card.foregroundColor, @"", nil);
            } else {
                cell.textLabel.text = @"Логотип";
                cell.detailTextLabel.text = _card.hasCustomLogo ? @"Свой" : (_card.brand ? @"Значок магазина" : @"Буква");
                cell.imageView.image = [_card iconWithSide:28 scale:0];
            }
            return cell;
        }
        default:
            if (indexPath.row == 0) return [self buttonCell:tableView title:@"Добавить в Passbook" color:blue];
            return [self buttonCell:tableView title:@"Удалить карту" color:[UIColor colorWithRed:0.80 green:0.15 blue:0.15 alpha:1]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.view endEditing:YES];

    switch (indexPath.section) {
        case WLSectionCard:
            if (indexPath.row == WLRowBrand) [self pickBrand];
            else [[self textFieldWithTag:WLFieldStore + (indexPath.row - WLRowStoreName)] becomeFirstResponder];
            break;
        case WLSectionNotes:
            [[self textFieldWithTag:WLFieldNotes] becomeFirstResponder];
            break;
        case WLSectionBarcode:
            if (indexPath.row == WLRowFormat) [self pickBarcodeFormat];
            else if (indexPath.row == WLRowScan) { if (_hasCamera) [self scan]; }
            else [self pickImageFor:WLPickBarcode];
            break;
        case WLSectionLook:
            if (indexPath.row == WLRowColor) [self pickColor];
            else [self chooseLogo];
            break;
        case WLSectionActions:
            if (indexPath.row == 0) [self addToPassbook];
            else [self confirmDelete];
            break;
    }
}

#pragma mark - Выбор значений

- (void)pickBrand {
    __weak WLCardEditViewController *weakSelf = self;
    WLStorePickerViewController *picker = [[WLStorePickerViewController alloc] initWithPrompt:nil selected:_card.brandId completion:^(WLBrand *brand) {
        WLCardEditViewController *me = weakSelf;
        if (!me) return;
        WLCard *card = me->_card;
        NSString *oldBrandName = card.brand.name;
        card.brandId = brand.identifier;
        if (brand) {
            // название подставляем, если оно пустое или было от прошлого пресета
            if (card.storeName.length == 0 || [card.storeName isEqualToString:oldBrandName]) card.storeName = brand.name;
            card.colorIndex = -1;
        } else if (card.colorIndex < 0) {
            card.colorIndex = 0;
        }
        [me.navigationController popViewControllerAnimated:YES];
        if (!brand) [[me textFieldWithTag:WLFieldStore] performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.5];
    }];
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)pickBarcodeFormat {
    NSArray *order = WLBarcodeFormatDisplayOrder();
    NSMutableArray *names = [NSMutableArray array];
    for (NSNumber *f in order) [names addObject:WLBarcodeFormatName(f.integerValue)];
    __weak WLCardEditViewController *weakSelf = self;
    WLOptionPickerViewController *picker = [[WLOptionPickerViewController alloc]
        initWithTitle:@"Штрихкод"
              options:names
               images:nil
             selected:[order indexOfObject:@(_card.barcodeFormat)]
               footer:@"Проще всего — отсканировать карту камерой, тип определится сам. Большинство скидочных карт — EAN-13 (13 цифр)."
           completion:^(NSInteger index) {
               WLCardEditViewController *me = weakSelf;
               if (me) me->_card.barcodeFormat = [order[index] integerValue];
           }];
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)pickColor {
    BOOL hasBrand = _card.brand != nil;
    NSMutableArray *names = [NSMutableArray array], *images = [NSMutableArray array];
    if (hasBrand) {
        [names addObject:@"Фирменный"];
        [images addObject:[_card.brand iconWithSide:28]];
    }
    for (NSInteger i = 0; i < WLColorCount(); i++) {
        [names addObject:WLColorName(i)];
        [images addObject:WLColorSwatch(i, 28)];
    }
    NSInteger offset = hasBrand ? 1 : 0;
    NSInteger selected = _card.usesBrandColors ? 0 : MAX(_card.colorIndex, 0) + offset;
    __weak WLCardEditViewController *weakSelf = self;
    WLOptionPickerViewController *picker = [[WLOptionPickerViewController alloc]
        initWithTitle:@"Цвет карты" options:names images:images selected:selected footer:nil
           completion:^(NSInteger index) {
               WLCardEditViewController *me = weakSelf;
               if (me) me->_card.colorIndex = index - offset;   // -1 => фирменный
           }];
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)chooseLogo {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Логотип на карте" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Выбрать из фото", nil];
    if (_card.hasCustomLogo) sheet.destructiveButtonIndex = [sheet addButtonWithTitle:@"Убрать свой логотип"];
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Отмена"];
    sheet.tag = WLSheetLogo;
    [sheet showInView:self.view];
}

#pragma mark - Сканирование и фото

- (void)applyScanResult:(WLScanResult *)result {
    _card.cardNumber = result.text;
    _card.barcodeFormat = result.format;
    [self syncFields];
    [self.tableView reloadData];
}

- (void)scan {
    __weak WLCardEditViewController *weakSelf = self;
    WLScannerViewController *scanner = [[WLScannerViewController alloc] initWithCompletion:^(WLScanResult *result) {
        WLCardEditViewController *me = weakSelf;
        if (result) [me applyScanResult:result];
        [me dismissViewControllerAnimated:YES completion:nil];
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:scanner];
    nav.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)pickImageFor:(NSInteger)purpose {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) return;
    _pickPurpose = purpose;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = (purpose == WLPickLogo);   // для логотипа даём обрезать
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    if (!image) return;

    if (_pickPurpose == WLPickLogo) {
        [[WLCardStore sharedStore] setCustomLogo:image forCard:_card];
        [self.tableView reloadData];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        WLScanResult *result = [[[WLBarcodeDecoder alloc] init] decodeImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) [self applyScanResult:result];
            else [self alert:@"Штрихкод не найден" message:@"Попробуйте более чёткое фото или скриншот."];
        });
    });
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Сохранение и Passbook

- (BOOL)validateAndSave {
    [self.view endEditing:YES];
    NSString *error = [_card validationError];
    if (error) {
        [self alert:@"Проверьте карту" message:error];
        return NO;
    }
    [[WLCardStore sharedStore] saveCard:_card];
    if (_isNew) {
        _isNew = NO;
        [self.tableView reloadData];
    }
    self.title = _card.storeName;
    return YES;
}

- (void)saveTapped {
    if ([self validateAndSave]) [self.navigationController popViewControllerAnimated:YES];
}

- (void)addToPassbook {
    if (![self validateAndSave]) return;
    [WLPassbookPresenter addCard:_card fromViewController:self];
}

- (void)confirmDelete {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Удалить карту из Walleter? Карта в Passbook останется — её можно удалить там."
                                                       delegate:self
                                              cancelButtonTitle:@"Отмена"
                                         destructiveButtonTitle:@"Удалить"
                                              otherButtonTitles:nil];
    sheet.tag = WLSheetDelete;
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) return;
    if (actionSheet.tag == WLSheetDelete) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [[WLCardStore sharedStore] removeCard:_card];
            [self.navigationController popViewControllerAnimated:YES];
        }
        return;
    }
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [[WLCardStore sharedStore] setCustomLogo:nil forCard:_card];
        [self.tableView reloadData];
    } else {
        [self pickImageFor:WLPickLogo];
    }
}

@end
