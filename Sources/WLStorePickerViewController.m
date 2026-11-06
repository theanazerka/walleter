#import "WLStorePickerViewController.h"

@implementation WLStorePickerViewController {
    NSString *_prompt;
    NSString *_selected;
    NSArray *_brands;
    void (^_completion)(WLBrand *);
}

- (id)initWithPrompt:(NSString *)prompt selected:(NSString *)selectedBrandId completion:(void (^)(WLBrand *))completion {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        _prompt = [prompt copy];
        _selected = [selectedBrandId copy];
        _brands = [WLBrand allBrands];
        _completion = [completion copy];
        self.title = @"Магазин";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 48;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : _brands.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? _prompt : @"Магазины";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"brand"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"brand"];
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Другой магазин…";
        cell.imageView.image = nil;
        cell.accessoryType = _selected.length ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
    } else {
        WLBrand *brand = _brands[indexPath.row];
        cell.textLabel.text = brand.name;
        cell.imageView.image = [brand iconWithSide:34];
        cell.accessoryType = [brand.identifier isEqualToString:_selected] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    WLBrand *brand = indexPath.section == 0 ? nil : _brands[indexPath.row];
    if (_completion) _completion(brand);
}

@end
