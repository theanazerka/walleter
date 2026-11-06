#import "WLCardEditViewController.h"
#import "WLOptionPickerViewController.h"
#import "WLCardStore.h"
#import "WLPassBuilder.h"
#import "WLColors.h"
#import <PassKit/PassKit.h>

enum { WLSectionCard, WLSectionBarcode, WLSectionColor, WLSectionNotes, WLSectionActions, WLSectionCount };
enum { WLFieldStore = 1, WLFieldNumber, WLFieldHolder, WLFieldNotes };

@interface WLCardEditViewController () <UITextFieldDelegate, UIActionSheetDelegate, PKAddPassesViewControllerDelegate>
@end

@implementation WLCardEditViewController {
    WLCard *_card;
    BOOL _isNew;
    NSMutableDictionary *_fieldCells;   // tag -> UITableViewCell
}

- (id)initWithCard:(WLCard *)card {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        _isNew = (card == nil);
        _card = card ? [card copy] : [WLCard newCard];
        _fieldCells = [NSMutableDictionary dictionary];
        self.title = _isNew ? @"Новая карта" : card.storeName;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Сохранить" style:UIBarButtonItemStyleDone target:self action:@selector(saveTapped)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_isNew && _card.storeName.length == 0) {
        [[self textFieldWithTag:WLFieldStore] becomeFirstResponder];
    }
}

#pragma mark - Fields

- (UITextField *)textFieldWithTag:(NSInteger)tag {
    return (UITextField *)[[self fieldCellForTag:tag] viewWithTag:tag];
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
            cell.textLabel.text = @"Магазин";
            field.placeholder = @"Например, Пятёрочка";
            field.text = _card.storeName;
            field.autocapitalizationType = UITextAutocapitalizationTypeWords;
            break;
        case WLFieldNumber:
            cell.textLabel.text = @"Номер";
            field.placeholder = @"Цифры под штрихкодом";
            field.text = _card.cardNumber;
            field.autocorrectionType = UITextAutocorrectionTypeNo;
            field.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            field.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            break;
        case WLFieldHolder:
            cell.textLabel.text = @"Владелец";
            field.placeholder = @"Необязательно";
            field.text = _card.holderName;
            field.autocapitalizationType = UITextAutocapitalizationTypeWords;
            break;
        case WLFieldNotes:
            cell.textLabel.text = @"Заметка";
            field.placeholder = @"Скидка 5%, PIN и т.п.";
            field.text = _card.notes;
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
    NSInteger next = textField.tag == WLFieldHolder ? WLFieldNotes : textField.tag + 1;
    if (textField.tag < WLFieldNotes) {
        [[self textFieldWithTag:next] becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return WLSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case WLSectionCard:    return 3;
        case WLSectionActions: return _isNew ? 1 : 2;
        default:               return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case WLSectionCard:    return @"Карта";
        case WLSectionBarcode: return @"Штрихкод";
        case WLSectionColor:   return @"Оформление";
        default:               return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == WLSectionBarcode) {
        return WLBarcodeFormatIsLinear(_card.barcodeFormat)
            ? @"Passbook в iOS 6 не умеет линейные штрихкоды, поэтому Walleter нарисует его картинкой на карте."
            : nil;
    }
    if (section == WLSectionActions) {
        return @"Для добавления в Passbook нужен твик SigPass.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case WLSectionCard:
            return [self fieldCellForTag:WLFieldStore + indexPath.row];
        case WLSectionNotes:
            return [self fieldCellForTag:WLFieldNotes];
        case WLSectionBarcode:
        case WLSectionColor: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"value"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"value"];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            if (indexPath.section == WLSectionBarcode) {
                cell.textLabel.text = @"Тип";
                cell.detailTextLabel.text = WLBarcodeFormatName(_card.barcodeFormat);
                cell.imageView.image = nil;
            } else {
                cell.textLabel.text = @"Цвет";
                cell.detailTextLabel.text = WLColorName(_card.colorIndex);
                cell.imageView.image = WLColorSwatch(_card.colorIndex, 28);
            }
            return cell;
        }
        default: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"action"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"action"];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
            }
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Добавить в Passbook";
                cell.textLabel.textColor = [UIColor colorWithRed:0.10 green:0.40 blue:0.80 alpha:1];
            } else {
                cell.textLabel.text = @"Удалить карту";
                cell.textLabel.textColor = [UIColor colorWithRed:0.80 green:0.15 blue:0.15 alpha:1];
            }
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.view endEditing:YES];

    switch (indexPath.section) {
        case WLSectionCard:
            [[self textFieldWithTag:WLFieldStore + indexPath.row] becomeFirstResponder];
            break;
        case WLSectionNotes:
            [[self textFieldWithTag:WLFieldNotes] becomeFirstResponder];
            break;
        case WLSectionBarcode:
            [self pickBarcodeFormat];
            break;
        case WLSectionColor:
            [self pickColor];
            break;
        case WLSectionActions:
            if (indexPath.row == 0) [self addToPassbook];
            else [self confirmDelete];
            break;
    }
}

#pragma mark - Pickers

- (void)pickBarcodeFormat {
    NSMutableArray *names = [NSMutableArray array];
    for (NSInteger i = 0; i < WLBarcodeFormatCount; i++) [names addObject:WLBarcodeFormatName(i)];
    __weak WLCardEditViewController *weakSelf = self;
    WLOptionPickerViewController *picker = [[WLOptionPickerViewController alloc]
        initWithTitle:@"Штрихкод"
              options:names
               images:nil
             selected:_card.barcodeFormat
               footer:@"Большинство скидочных карт — EAN-13 (13 цифр). Если цифр другое количество или есть буквы — Code 128."
           completion:^(NSInteger index) {
               WLCardEditViewController *strongSelf = weakSelf;
               if (!strongSelf) return;
               strongSelf->_card.barcodeFormat = index;
               [strongSelf.tableView reloadData];
           }];
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)pickColor {
    NSMutableArray *names = [NSMutableArray array], *images = [NSMutableArray array];
    for (NSInteger i = 0; i < WLColorCount(); i++) {
        [names addObject:WLColorName(i)];
        [images addObject:WLColorSwatch(i, 28)];
    }
    __weak WLCardEditViewController *weakSelf = self;
    WLOptionPickerViewController *picker = [[WLOptionPickerViewController alloc]
        initWithTitle:@"Цвет карты"
              options:names
               images:images
             selected:_card.colorIndex
               footer:nil
           completion:^(NSInteger index) {
               WLCardEditViewController *strongSelf = weakSelf;
               if (!strongSelf) return;
               strongSelf->_card.colorIndex = index;
               [strongSelf.tableView reloadData];
           }];
    [self.navigationController pushViewController:picker animated:YES];
}

#pragma mark - Actions

- (void)showAlert:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (BOOL)validateAndSave {
    [self.view endEditing:YES];
    NSString *error = [_card validationError];
    if (error) {
        [self showAlert:@"Проверьте карту" message:error];
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
    if ([self validateAndSave]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)addToPassbook {
    if (![self validateAndSave]) return;

    if (NSClassFromString(@"PKPassLibrary") == nil || ![PKPassLibrary isPassLibraryAvailable]) {
        [self showAlert:@"Passbook недоступен" message:@"На этом устройстве нет Passbook (например, на iPad в iOS 6)."];
        return;
    }

    NSString *buildError = nil;
    NSData *data = [WLPassBuilder pkpassDataForCard:_card error:&buildError];
    if (!data) {
        [self showAlert:@"Не получилось" message:buildError];
        return;
    }

    NSError *passError = nil;
    PKPass *pass = [[PKPass alloc] initWithData:data error:&passError];
    if (!pass) {
        NSString *msg = [NSString stringWithFormat:@"Passbook отклонил карту%@.\n\nУбедитесь, что установлен твик SigPass, и перезагрузите устройство (или сделайте respring).",
                         passError ? [NSString stringWithFormat:@" (%@)", passError.localizedDescription] : @""];
        [self showAlert:@"Ошибка Passbook" message:msg];
        return;
    }

    PKAddPassesViewController *add = [[PKAddPassesViewController alloc] initWithPass:pass];
    if (!add) {
        [self showAlert:@"Ошибка Passbook" message:@"Не удалось открыть экран добавления карты."];
        return;
    }
    add.delegate = self;
    [self presentViewController:add animated:YES completion:nil];
}

- (void)addPassesViewControllerDidFinish:(PKAddPassesViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)confirmDelete {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Удалить карту из Walleter? Карта в Passbook останется — её можно удалить там."
                                                       delegate:self
                                              cancelButtonTitle:@"Отмена"
                                         destructiveButtonTitle:@"Удалить"
                                              otherButtonTitles:nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [[WLCardStore sharedStore] removeCard:_card];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
