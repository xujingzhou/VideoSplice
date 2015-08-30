
#import <UIKit/UIKit.h>

typedef enum
{
    LeafNotificationTypeWarrning,
    LeafNotificationTypeSuccess
}LeafNotificationType;

@interface LeafNotification : UIView

@property (nonatomic,assign) NSTimeInterval duration;
@property(nonatomic,assign) LeafNotificationType type;

@property (nonatomic, strong) dispatch_block_t tapHandler;

- (instancetype)initWithController:(UIViewController *)controller text:(NSString *)text;

- (void)showWithAnimation:(BOOL)animation;
- (void)dismissWithAnimation:(BOOL)animation;

+ (void)showInController:(UIViewController *)controller withText:(NSString *)text type:(LeafNotificationType)type withTapBlock:(dispatch_block_t)tapHandler;

+ (void)showInController:(UIViewController *)controller withText:(NSString *)text withTapBlock:(dispatch_block_t)tapHandler;

@end
