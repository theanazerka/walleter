#import "WLOptionPickerViewController.h"

@implementation WLOptionPickerViewController {
    NSArray *_options;
    NSArray *_images;
    NSInteger _selected;
    NSString *_footer;
    void (^_completion)(NSInteger);
}

- (id)initWithTitle:(NSString *)title options:(NSArray *)options images:(NSArray *)images selected:(NSInteger)selected footer:(NSString *)footer completion:(void (^)(NSInteger))completion {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        self.title = title;
        _options = [options copy];
        _images = [images copy];
        _selected = selected;
        _footer = [footer copy];
        _completion = [completion copy];
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _options.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return _footer;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"opt"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"opt"];
    cell.textLabel.text = _options[indexPath.row];
    cell.imageView.image = indexPath.row < (NSInteger)_images.count ? _images[indexPath.row] : nil;
    cell.accessoryType = indexPath.row == _selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _selected = indexPath.row;
    if (_completion) _completion(_selected);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
