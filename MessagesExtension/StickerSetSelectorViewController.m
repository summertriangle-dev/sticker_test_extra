//
//  StickerSetSelectorViewController.m
//  sticker_test_extra
//

#import "StickerSetSelectorViewController.h"

NSString *const AggregateSetName = @"Everything";

@interface StickerSetSelectorViewController ()
@property NSArray<NSString *> *packList;
@end

@implementation StickerSetSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *spRoot = [NSBundle.mainBundle pathForResource:@"Stickers" ofType:nil];
    self.packList = [[NSFileManager.defaultManager contentsOfDirectoryAtPath:spRoot error:nil] filteredArrayUsingPredicate:
     [NSPredicate predicateWithBlock:^BOOL(NSString *evaluatedObject, NSDictionary *unused) {
        return [evaluatedObject hasSuffix:@".stickerpack"];
    }]];

    if (self.listener) {
        if ([self.listener.nameOfSelectedStickerSet isEqualToString:AggregateSetName]) {
            self.indexOfSelectedStickerPack = 0;
        } else {
            self.indexOfSelectedStickerPack = [self.packList indexOfObject:self.listener.nameOfSelectedStickerSet] + 1;
        }
    }

    if (self.indexOfSelectedStickerPack == NSNotFound) {
        self.indexOfSelectedStickerPack = 0;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.packList.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Selectable" forIndexPath:indexPath];

    if (indexPath.row > 0) {
        cell.textLabel.text = [self.packList[indexPath.row - 1] stringByDeletingPathExtension];
    } else {
        cell.textLabel.text = @"All Stickers";
    }

    if (indexPath.row == self.indexOfSelectedStickerPack) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.listener) {
        if (indexPath.row > 0) {
            [self.listener didSelectStickerSet:self.packList[indexPath.row - 1]];
        } else {
            [self.listener didSelectStickerSet:AggregateSetName];
        }
    }

    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
