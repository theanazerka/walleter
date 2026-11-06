#import "WLCardListViewController.h"
#import "WLCardEditViewController.h"
#import "WLCardStore.h"
#import "WLColors.h"

@implementation WLCardListViewController {
    UILabel *_emptyLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Мои карты";
    self.tableView.rowHeight = 60;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCard)];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    _emptyLabel = [[UILabel alloc] initWithFrame:CGRectInset(self.view.bounds, 30, 0)];
    _emptyLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _emptyLabel.numberOfLines = 0;
    _emptyLabel.textAlignment = NSTextAlignmentCenter;
    _emptyLabel.textColor = [UIColor grayColor];
    _emptyLabel.backgroundColor = [UIColor clearColor];
    _emptyLabel.font = [UIFont systemFontOfSize:17];
    _emptyLabel.text = @"Карт пока нет.\n\nНажмите «+», чтобы добавить скидочную карту и отправить её в Passbook.";
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

- (void)addCard {
    WLCardEditViewController *edit = [[WLCardEditViewController alloc] initWithCard:nil];
    [self.navigationController pushViewController:edit animated:YES];
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
    cell.imageView.image = WLColorSwatch(card.colorIndex, 40);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WLCard *card = [WLCardStore sharedStore].cards[indexPath.row];
    WLCardEditViewController *edit = [[WLCardEditViewController alloc] initWithCard:card];
    [self.navigationController pushViewController:edit animated:YES];
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
