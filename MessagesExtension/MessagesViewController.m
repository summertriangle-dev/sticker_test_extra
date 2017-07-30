//
//  MessagesViewController.m
//  MessagesExtension
//

#import "MessagesViewController.h"
#import "StickerSetSelectorViewController.h"

@interface MessagesViewController () <StickerSetSelectorListening, MSStickerBrowserViewDataSource>

@property (strong, nonatomic) NSString *selectedPackName;
@property (strong) NSArray<MSSticker *> *stickers;
@property (strong, nonatomic) IBOutlet UIButton *stickerSetButton;
@property (strong, nonatomic) IBOutlet MSStickerBrowserView *stickerBrowserView;

@end

@implementation MessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.stickerBrowserView.dataSource = self;
}

- (void)setSelectedPackName:(NSString *)selectedPackName {
    _selectedPackName = selectedPackName;

    [UIView performWithoutAnimation:^{
        [self.stickerSetButton setTitle:[NSString stringWithFormat:@"Set: %@", [selectedPackName stringByDeletingPathExtension]] forState:UIControlStateNormal];
        [self.stickerSetButton layoutIfNeeded];
    }];

    [NSUserDefaults.standardUserDefaults setObject:self.selectedPackName forKey:@"SelectedPack"];
}

- (void)reloadStickerInfo {
    NSMutableArray<MSSticker *> *stickers = [[NSMutableArray alloc] init];

    if ([self.selectedPackName isEqualToString:AggregateSetName]) {
        [self reloadStickerInfoUsingAggregateIntoArray:stickers];
    } else {
        [self reloadStickerInfoUsingSet:self.selectedPackName intoArray:stickers];
    }

    self.stickers = stickers;
    [self.stickerBrowserView reloadData];

    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect previous = CGRectFromString([NSUserDefaults.standardUserDefaults stringForKey:[@"VisibleRect." stringByAppendingString:self.selectedPackName]]);
        previous.size = self.stickerBrowserView.bounds.size;
        UICollectionView *scrollView = self.stickerBrowserView.subviews[0];
        [scrollView scrollRectToVisible:previous animated:NO];
    });
}

- (void)reloadStickerInfoUsingSet:(NSString *)setName intoArray:(NSMutableArray<MSSticker *> *)stickers {
    NSString *spRoot = [NSBundle.mainBundle pathForResource:@"Stickers" ofType:nil];
    NSString *pkRoot = [spRoot stringByAppendingPathComponent:setName];
    NSArray *fsStickers = [[NSFileManager.defaultManager contentsOfDirectoryAtPath:pkRoot error:nil] sortedArrayUsingSelector:@selector(compare:)];

    [fsStickers enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        NSURL *img = [NSURL fileURLWithPath:[pkRoot stringByAppendingPathComponent:obj]];
        NSError *error;
        MSSticker *s = [[MSSticker alloc] initWithContentsOfFileURL:img localizedDescription:obj.stringByDeletingPathExtension error:&error];

        if (s) {
            [stickers addObject:s];
        } else {
            NSLog(@"load sticker: %@ failed: %@", img.path, error);
        }
    }];
}

- (void)reloadStickerInfoUsingAggregateIntoArray:(NSMutableArray<MSSticker *> *)stickers {
    NSString *spRoot = [NSBundle.mainBundle pathForResource:@"Stickers" ofType:nil];
    [[NSFileManager.defaultManager contentsOfDirectoryAtPath:spRoot error:nil] enumerateObjectsUsingBlock:^(NSString *setName, NSUInteger idx, BOOL *stop) {
        if ([setName hasSuffix:@".stickerpack"]) {
            [self reloadStickerInfoUsingSet:setName intoArray:stickers];
        }
    }];
}

#pragma mark - Conversation Handling

-(void)didBecomeActiveWithConversation:(MSConversation *)conversation {
    self.selectedPackName = [NSUserDefaults.standardUserDefaults stringForKey:@"SelectedPack"] ?: AggregateSetName;
    [self reloadStickerInfo];
}

-(void)willResignActiveWithConversation:(MSConversation *)conversation {
    [NSUserDefaults.standardUserDefaults setObject:self.selectedPackName forKey:@"SelectedPack"];
    UICollectionView *scrollView = self.stickerBrowserView.subviews[0];
    CGRect visible = (CGRect){scrollView.contentOffset, CGSizeZero};
    [NSUserDefaults.standardUserDefaults setObject:NSStringFromCGRect(visible) forKey:[@"VisibleRect." stringByAppendingString:self.selectedPackName]];
}

- (IBAction)presentStickerPicker:(id)sender {
    StickerSetSelectorViewController *picker = [[UIStoryboard storyboardWithName:@"MainInterface" bundle:NSBundle.mainBundle] instantiateViewControllerWithIdentifier:@"StickerPicker"];
    picker.listener = self;

    ((UITableView *)picker.view).contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0);
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - StickerSetSelectorListening Protocol

- (void)didSelectStickerSet:(NSString *)set {
    UICollectionView *scrollView = self.stickerBrowserView.subviews[0];
    CGRect visible = (CGRect){scrollView.contentOffset, CGSizeZero};
    [NSUserDefaults.standardUserDefaults setObject:NSStringFromCGRect(visible) forKey:[@"VisibleRect." stringByAppendingString:self.selectedPackName]];

    self.selectedPackName = set;
    [self reloadStickerInfo];
}

- (NSString *)nameOfSelectedStickerSet {
    return self.selectedPackName;
}

#pragma mark - Sticker Browser Data Source

- (NSInteger)numberOfStickersInStickerBrowserView:(MSStickerBrowserView *)stickerBrowserView {
    return self.stickers.count;
}

- (MSSticker *)stickerBrowserView:(MSStickerBrowserView *)stickerBrowserView stickerAtIndex:(NSInteger)index {
    return self.stickers[index];
}

@end
