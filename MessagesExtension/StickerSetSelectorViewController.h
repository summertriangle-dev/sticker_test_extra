//
//  StickerSetSelectorViewController.h
//  sticker_test_extra
//

#import <UIKit/UIKit.h>

extern NSString *const AggregateSetName;

@protocol StickerSetSelectorListening <NSObject>

- (void)didSelectStickerSet:(NSString *)set;
- (NSString *)nameOfSelectedStickerSet;

@end

@interface StickerSetSelectorViewController : UITableViewController

@property (weak) id<StickerSetSelectorListening> listener;
@property NSInteger indexOfSelectedStickerPack;

@end
