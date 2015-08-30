//
//  ViewController.m
//  PicInPic
//
//  Created by Johnny Xu(徐景周) on 6/12/15.
//  Copyright (c) 2015 Future Studio. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <StoreKit/StoreKit.h>

#import "ViewController.h"
#import "PBJVideoPlayerController.h"
#import "CaptureViewController.h"
#import "JGActionSheet.h"
#import "DBPrivateHelperController.h"
#import "KGModal.h"
#import "AudioViewController.h"
#import "CMPopTipView.h"
#import "UIAlertView+Blocks.h"
#import "LeafNotification.h"
#import "ExportEffects.h"
#import "NYSegmentedControl.h"
#import "IGAssetsPicker.h"

#if USES_IASK_STATIC_LIBRARY
#import "InAppSettingsKit/IASKAppSettingsViewController.h"
#else
#import "IASKAppSettingsViewController.h"
#endif

typedef NS_ENUM(NSUInteger, VideoPositionType)
{
    kPositionNone = 0,
    kPositionHorizontal = 1,
    kPositionVertical,
    kPositionSquareLeftTop,
    kPositionSquareRightTop,
    kPositionSquareLeftBottom,
    kPositionSquareRightBottom,
};

#define MaxVideoLength MAX_VIDEO_DUR

#define DemoHorizontalVideoName @"Horizontal.mp4"
#define DemoVerticalVideoName @"Vertical.mp4"
#define DemoSquareVideoName @"Square.mp4"

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, PBJVideoPlayerControllerDelegate, SKStoreProductViewControllerDelegate, IGAssetsPickerDelegate, IASKSettingsDelegate, UIPopoverControllerDelegate>
{
    CMPopTipView *_popTipView;
    LeafNotification *_notification;
}

@property (nonatomic, strong) PBJVideoPlayerController *demoVideoPlayerController;
@property (nonatomic, strong) UIView *demoVideoContentView;
@property (nonatomic, strong) UIImageView *demoPlayButton;

@property (nonatomic, strong) UIScrollView *captureContentViewHorizontal;
@property (nonatomic, strong) UIScrollView *captureContentViewVertical;
@property (nonatomic, strong) UIScrollView *captureContentViewSquare;
@property (nonatomic, strong) UIButton *videoViewHorizontal;
@property (nonatomic, strong) UIButton *videoViewVertical;
@property (nonatomic, strong) UIButton *videoViewSquareLeftTop;
@property (nonatomic, strong) UIButton *videoViewSquareRightTop;
@property (nonatomic, strong) UIButton *videoViewSquareLeftBottom;
@property (nonatomic, strong) UIButton *videoViewSquareRightBottom;

@property (nonatomic, strong) UIScrollView *videoContentViewHorizontal;
@property (nonatomic, strong) UIScrollView *videoContentViewVertical;
@property (nonatomic, strong) UIScrollView *videoContentViewSquare;
@property (nonatomic, strong) PBJVideoPlayerController *videoPlayerControllerHorizontal;
@property (nonatomic, strong) PBJVideoPlayerController *videoPlayerControllerVertical;
@property (nonatomic, strong) PBJVideoPlayerController *videoPlayerControllerSquareLeftTop;
@property (nonatomic, strong) PBJVideoPlayerController *videoPlayerControllerSquareRightTop;
@property (nonatomic, strong) PBJVideoPlayerController *videoPlayerControllerSquareLeftBottom;
@property (nonatomic, strong) PBJVideoPlayerController *videoPlayerControllerSquareRightBottom;
@property (nonatomic, strong) UIImageView *playButtonHorizontal;
@property (nonatomic, strong) UIImageView *playButtonVertical;
@property (nonatomic, strong) UIImageView *playButtonSquareLeftTop;
@property (nonatomic, strong) UIImageView *playButtonSquareRightTop;
@property (nonatomic, strong) UIImageView *playButtonSquareLeftBottom;
@property (nonatomic, strong) UIImageView *playButtonSquareRightBottom;
@property (nonatomic, strong) UIButton *closeVideoPlayerButtonHorizontal;
@property (nonatomic, strong) UIButton *closeVideoPlayerButtonVertical;
@property (nonatomic, strong) UIButton *closeVideoPlayerButtonSquareLeftTop;
@property (nonatomic, strong) UIButton *closeVideoPlayerButtonSquareRightTop;
@property (nonatomic, strong) UIButton *closeVideoPlayerButtonSquareLeftBottom;
@property (nonatomic, strong) UIButton *closeVideoPlayerButtonSquareRightBottom;

@property (nonatomic, copy) NSURL *videoPickURLHorizontal;
@property (nonatomic, copy) NSURL *videoPickURLVertical;
@property (nonatomic, copy) NSURL *videoPickURLSquareLeftTop;
@property (nonatomic, copy) NSURL *videoPickURLSquareRightTop;
@property (nonatomic, copy) NSURL *videoPickURLSquareLeftBottom;
@property (nonatomic, copy) NSURL *videoPickURLSquareRightBottom;
@property (nonatomic, copy) NSString *audioPickFile;

@property (nonatomic, assign) MirrorType mirrorType;
@property (nonatomic, assign) VideoPositionType videoPositionType;

@property (nonatomic, strong) NYSegmentedControl *segmentedControl;
@property (nonatomic, strong) UIView *visibleParentView;
@property (nonatomic, strong) UIView *horizontalParentView;
@property (nonatomic, strong) UIView *verticalParentView;
@property (nonatomic, strong) UIView *squareParentView;
@property (nonatomic, strong) NSArray *mirrorParentViews;

@property (nonatomic, strong) UIButton *demoButton;

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;
@property (nonatomic) UIPopoverController* currentPopoverController;

@end

@implementation ViewController

#pragma mark - Contact US
- (void)createContactUS
{
    if (_notification)
    {
        [_notification dismissWithAnimation:NO];
        _notification = nil;
    }
    
    __weak typeof(self) weakSelf = self;
    _notification = [[LeafNotification alloc] initWithController:self text:GBLocalizedString(@"ContactUS")];
    [self.view addSubview:_notification];
    _notification.type = LeafNotificationTypeWarrning;
    _notification.tapHandler = ^{
        
        NSLog(@"contactUs");
        [weakSelf contactUs];
    };
    [_notification showWithAnimation:YES];
}

- (void)contactUs
{
    NSString *url = @"mailto:1409694515@qq.com";
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
}

#pragma mark - Authorization Helper
- (void)popupAlertView
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:GBLocalizedString(@"Private_Setting_Audio_Tips") delegate:nil cancelButtonTitle:GBLocalizedString(@"IKnow") otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)popupAuthorizationHelper:(id)type
{
    DBPrivateHelperController *privateHelper = [DBPrivateHelperController helperForType:[type longValue]];
    privateHelper.snapshot = [self snapshot];
    privateHelper.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:privateHelper animated:YES completion:nil];
}

- (UIImage *)snapshot
{
    id <UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
    UIGraphicsBeginImageContextWithOptions(appDelegate.window.bounds.size, NO, appDelegate.window.screen.scale);
    [appDelegate.window drawViewHierarchyInRect:appDelegate.window.bounds afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return snapshotImage;
}

#pragma mark - File Helper
- (AVURLAsset *)getURLAsset:(NSString *)filePath
{
    NSURL *videoURL = getFileURL(filePath);
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    
    return asset;
}

#pragma mark - Delete Temp Files
- (void)deleteTempDirectory
{
    NSString *dir = NSTemporaryDirectory();
    deleteFilesAt(dir, @"mov");
}

#pragma mark - Custom ActionSheet
- (void)showCustomActionSheetByView:(UIView *)anchor
{
    UIView *locationAnchor = anchor;
    if ([locationAnchor isKindOfClass:[UIButton class]])
    {
        if (locationAnchor.tag > 0)
        {
            _videoPositionType = locationAnchor.tag;
            NSLog(@"showCustomActionSheetByView videoPositionType: %ld", (unsigned long)_videoPositionType);
        }
    }
    
    NSString *videoTitle = [NSString stringWithFormat:@"%@", GBLocalizedString(@"SelectVideo")];
    JGActionSheetSection *sectionVideo = [JGActionSheetSection sectionWithTitle:videoTitle
                                                                        message:nil
                                                                   buttonTitles:@[
                                                                                  GBLocalizedString(@"Camera"),
                                                                                  GBLocalizedString(@"PhotoAlbum")
                                                                                  ]
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
    [sectionVideo setButtonStyle:JGActionSheetButtonStyleBlue forButtonAtIndex:0];
    [sectionVideo setButtonStyle:JGActionSheetButtonStyleBlue forButtonAtIndex:1];
    
    NSArray *sections = (iPad ? @[sectionVideo] : @[sectionVideo, [JGActionSheetSection sectionWithTitle:nil message:nil buttonTitles:@[GBLocalizedString(@"Cancel")] buttonStyle:JGActionSheetButtonStyleCancel]]);
    JGActionSheet *sheet = [[JGActionSheet alloc] initWithSections:sections];
    
    [sheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath)
     {
         NSLog(@"indexPath: %ld; section: %ld", (long)indexPath.row, (long)indexPath.section);
         
         if (indexPath.section == 0)
         {
             if (indexPath.row == 0)
             {
                 // Check permission for Video & Audio
                 [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted)
                  {
                      if (!granted)
                      {
                          [self performSelectorOnMainThread:@selector(popupAlertView) withObject:nil waitUntilDone:YES];
                          return;
                      }
                      else
                      {
                          [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
                           {
                               if (!granted)
                               {
                                   [self performSelectorOnMainThread:@selector(popupAuthorizationHelper:) withObject:[NSNumber numberWithLong:DBPrivacyTypeCamera] waitUntilDone:YES];
                                   return;
                               }
                               else
                               {
                                   // Has permisstion
                                   [self performSelectorOnMainThread:@selector(pickBackgroundVideoFromCamera) withObject:nil waitUntilDone:NO];
                               }
                           }];
                      }
                  }];
             }
             else if (indexPath.row == 1)
             {
                 // Check permisstion for photo album
                 ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
                 if (authStatus == ALAuthorizationStatusRestricted || authStatus == ALAuthorizationStatusDenied)
                 {
                     [self performSelectorOnMainThread:@selector(popupAuthorizationHelper:) withObject:[NSNumber numberWithLong:DBPrivacyTypePhoto] waitUntilDone:YES];
                     return;
                 }
                 else
                 {
                     // Has permisstion to execute
                     if (_mirrorType == kMirror4Square)
                     {
                         [self performSelector:@selector(pickVideoFromInstagramPhotosAlbum) withObject:nil afterDelay:0.1];
                     }
                     else
                     {
                         [self performSelector:@selector(pickBackgroundVideoFromPhotosAlbum) withObject:nil afterDelay:0.1];
                     }
                 }
             }
         }
         
         [sheet dismissAnimated:YES];
     }];
    
    if (iPad)
    {
        [sheet setOutsidePressBlock:^(JGActionSheet *sheet)
         {
             [sheet dismissAnimated:YES];
         }];
        
        CGPoint point = (CGPoint){ CGRectGetMidX(locationAnchor.bounds), CGRectGetMaxY(locationAnchor.bounds) };
        point = [self.navigationController.view convertPoint:point fromView:locationAnchor];
        
        [sheet showFromPoint:point inView:self.navigationController.view arrowDirection:JGActionSheetArrowDirectionTop animated:YES];
    }
    else
    {
        [sheet setOutsidePressBlock:^(JGActionSheet *sheet)
         {
             [sheet dismissAnimated:YES];
         }];
        
        [sheet showInView:self.navigationController.view animated:YES];
    }
}

- (void)showCustomActionSheetByNav:(UIBarButtonItem *)barButtonItem withEvent:(UIEvent *)event
{
    UIView *anchor = [event.allTouches.anyObject view];
    [self showCustomActionSheetByView:anchor];
}

#pragma mark - appSettingsViewController
- (IASKAppSettingsViewController*)appSettingsViewController
{
    if (!_appSettingsViewController)
    {
        _appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
        _appSettingsViewController.delegate = self;
//        [_appSettingsViewController setShowCreditsFooter:NO];
    }
    
    return _appSettingsViewController;
}

- (void)showSettingsModal:(id)sender
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        [self showSettingsPopover:sender];
    }
    else
    {
        [self.navigationController pushViewController:self.appSettingsViewController animated:YES];
        
//        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.appSettingsViewController];
//        self.appSettingsViewController.showDoneButton = YES;
//        [self presentViewController:navController animated:NO completion:nil];
    }
}

- (void)showSettingsPopover:(id)sender
{
    if(self.currentPopoverController)
    {
        [self dismissCurrentPopover];
        return;
    }
    
    self.appSettingsViewController.showDoneButton = NO;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.appSettingsViewController];
    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:navController];
    popover.delegate = self;
    [popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:NO];
    self.currentPopoverController = popover;
}

- (void) dismissCurrentPopover
{
    [self.currentPopoverController dismissPopoverAnimated:YES];
    self.currentPopoverController = nil;
}

#pragma mark - UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.currentPopoverController = nil;
}

#pragma mark IASKAppSettingsViewControllerDelegate
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
//    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
    
    if (![self getShouldDisplayDemoButton])
    {
        _demoButton.hidden = YES;
    }
    else
    {
        _demoButton.hidden = NO;
    }
}

#pragma mark - PBJVideoPlayerControllerDelegate
- (void)videoPlayerReady:(PBJVideoPlayerController *)videoPlayer
{
    //NSLog(@"Max duration of the video: %f", videoPlayer.maxDuration);
}

- (void)videoPlayerPlaybackStateDidChange:(PBJVideoPlayerController *)videoPlayer
{
}

- (void)videoPlayerPlaybackWillStartFromBeginning:(PBJVideoPlayerController *)videoPlayer
{
    if (videoPlayer == _videoPlayerControllerHorizontal)
    {
        _playButtonHorizontal.alpha = 1.0f;
        _playButtonHorizontal.hidden = NO;
        
        [UIView animateWithDuration:0.1f animations:^{
            _playButtonHorizontal.alpha = 0.0f;
        } completion:^(BOOL finished)
         {
             _playButtonHorizontal.hidden = YES;
         }];
    }
    else if (videoPlayer == _videoPlayerControllerVertical)
    {
        _playButtonVertical.alpha = 1.0f;
        _playButtonVertical.hidden = NO;
        
        [UIView animateWithDuration:0.1f animations:^{
            _playButtonVertical.alpha = 0.0f;
        } completion:^(BOOL finished)
         {
             _playButtonVertical.hidden = YES;
         }];
    }
    else if (videoPlayer == _videoPlayerControllerSquareLeftBottom)
    {
        _playButtonSquareLeftBottom.alpha = 1.0f;
        _playButtonSquareLeftBottom.hidden = NO;
        
        [UIView animateWithDuration:0.1f animations:^{
            _playButtonSquareLeftBottom.alpha = 0.0f;
        } completion:^(BOOL finished)
         {
             _playButtonSquareLeftBottom.hidden = YES;
         }];
    }
    else if (videoPlayer == _videoPlayerControllerSquareLeftTop)
    {
        _playButtonSquareLeftTop.alpha = 1.0f;
        _playButtonSquareLeftTop.hidden = NO;
        
        [UIView animateWithDuration:0.1f animations:^{
            _playButtonSquareLeftTop.alpha = 0.0f;
        } completion:^(BOOL finished)
         {
             _playButtonSquareLeftTop.hidden = YES;
         }];
    }
    else if (videoPlayer == _videoPlayerControllerSquareRightBottom)
    {
        _playButtonSquareRightBottom.alpha = 1.0f;
        _playButtonSquareRightBottom.hidden = NO;
        
        [UIView animateWithDuration:0.1f animations:^{
            _playButtonSquareRightBottom.alpha = 0.0f;
        } completion:^(BOOL finished)
         {
             _playButtonSquareRightBottom.hidden = YES;
         }];
    }
    else if (videoPlayer == _videoPlayerControllerSquareRightTop)
    {
        _playButtonSquareRightTop.alpha = 1.0f;
        _playButtonSquareRightTop.hidden = NO;
        
        [UIView animateWithDuration:0.1f animations:^{
            _playButtonSquareRightTop.alpha = 0.0f;
        } completion:^(BOOL finished)
         {
             _playButtonSquareRightTop.hidden = YES;
         }];
    }
    else if (videoPlayer == _demoVideoPlayerController)
    {
        _demoPlayButton.alpha = 1.0f;
        _demoPlayButton.hidden = NO;
        
        [UIView animateWithDuration:0.1f animations:^{
            _demoPlayButton.alpha = 0.0f;
        } completion:^(BOOL finished)
         {
             _demoPlayButton.hidden = YES;
         }];
    }
}

- (void)videoPlayerPlaybackDidEnd:(PBJVideoPlayerController *)videoPlayer
{
    if (videoPlayer == _videoPlayerControllerHorizontal)
    {
        _playButtonHorizontal.hidden = NO;
        
        [UIView animateWithDuration:0.1f animations:^{
            _playButtonHorizontal.alpha = 1.0f;
        } completion:^(BOOL finished)
         {
             
         }];
    }
    else if (videoPlayer == _videoPlayerControllerVertical)
    {
        _playButtonVertical.hidden = NO;
        
        [UIView animateWithDuration:0.1f animations:^{
            _playButtonVertical.alpha = 1.0f;
        } completion:^(BOOL finished)
         {
             
         }];
    }
//    else if (videoPlayer == _videoPlayerControllerSquareLeftBottom)
//    {
//        _playButtonSquareLeftBottom.hidden = NO;
//        
//        [UIView animateWithDuration:0.1f animations:^{
//            _playButtonSquareLeftBottom.alpha = 1.0f;
//        } completion:^(BOOL finished)
//         {
//         }];
//    }
//    else if (videoPlayer == _videoPlayerControllerSquareLeftTop)
//    {
//        _playButtonSquareLeftTop.hidden = NO;
//        
//        [UIView animateWithDuration:0.1f animations:^{
//            _playButtonSquareLeftTop.alpha = 1.0f;
//        } completion:^(BOOL finished)
//         {
//             
//         }];
//    }
//    else if (videoPlayer == _videoPlayerControllerSquareRightBottom)
//    {
//        _playButtonSquareRightBottom.hidden = NO;
//        
//        [UIView animateWithDuration:0.1f animations:^{
//            _playButtonSquareRightBottom.alpha = 1.0f;
//        } completion:^(BOOL finished)
//         {
//             
//         }];
//    }
//    else if (videoPlayer == _videoPlayerControllerSquareRightTop)
//    {
//        _playButtonSquareRightTop.hidden = NO;
//        
//        [UIView animateWithDuration:0.1f animations:^{
//            _playButtonSquareRightTop.alpha = 1.0f;
//        } completion:^(BOOL finished)
//         {
//             
//         }];
//    }
    else if (videoPlayer == _demoVideoPlayerController)
    {
        _demoPlayButton.hidden = NO;
        
        [UIView animateWithDuration:0.1f animations:^{
            _demoPlayButton.alpha = 1.0f;
        } completion:^(BOOL finished)
         {
             
         }];
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 1.
    [self dismissViewControllerAnimated:NO completion:nil];
    
    NSLog(@"info = %@",info);
    
    // 2.
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if([mediaType isEqualToString:@"public.movie"])
    {
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        [self setPickedVideo:url];
    }
    else
    {
        NSLog(@"Error media type");
        return;
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:NO completion:nil];
}

- (void)setPickedVideo:(NSURL *)url
{
    [self setPickedVideo:url checkVideoLength:YES];
}

- (void)setPickedVideo:(NSURL *)url checkVideoLength:(BOOL)checkVideoLength
{
    if (!url || (url && ![url isFileURL]))
    {
        NSLog(@"Input video url is invalid.");
        return;
    }
    
    if (checkVideoLength)
    {
        if (getVideoDuration(url) > MaxVideoLength)
        {
            NSString *ok = GBLocalizedString(@"OK");
            NSString *error = GBLocalizedString(@"Error");
            NSString *fileLenHint = GBLocalizedString(@"FileLenHint");
            NSString *seconds = GBLocalizedString(@"Seconds");
            NSString *hint = [fileLenHint stringByAppendingFormat:@" %.0f ", MaxVideoLength];
            hint = [hint stringByAppendingString:seconds];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:error
                                                            message:hint
                                                           delegate:nil
                                                  cancelButtonTitle:ok
                                                  otherButtonTitles: nil];
            [alert show];
            
            return;
        }
    }
    
    switch (_videoPositionType)
    {
        case kPositionHorizontal:
        {
            _videoPickURLHorizontal = url;
            NSLog(@"Pick background video is success in kPositionHorizontal: %@", _videoPickURLHorizontal);
            break;
        }
        case kPositionVertical:
        {
            _videoPickURLVertical = url;
            NSLog(@"Pick background video is success in kPositionVertical: %@", _videoPickURLVertical);
            break;
        }
        case kPositionSquareLeftBottom:
        {
            _videoPickURLSquareLeftBottom = url;
            NSLog(@"Pick background video is success in kPositionSquareLeftBottom: %@", _videoPickURLSquareLeftBottom);
            break;
        }
        case kPositionSquareLeftTop:
        {
            _videoPickURLSquareLeftTop = url;
            NSLog(@"Pick background video is success in kPositionSquareLeftTop: %@", _videoPickURLSquareLeftTop);
            break;
        }
        case kPositionSquareRightBottom:
        {
            _videoPickURLSquareRightBottom = url;
            NSLog(@"Pick background video is success in kPositionSquareRightBottom: %@", _videoPickURLSquareRightBottom);
            break;
        }
        case kPositionSquareRightTop:
        {
            _videoPickURLSquareRightTop = url;
            NSLog(@"Pick background video is success in kPositionSquareRightTop: %@", _videoPickURLSquareRightTop);
            break;
        }
        default:
            break;
    }
    
    [self reCalcVideoSize:[url relativePath]];
    
    // Setting
    [self defaultVideoSetting:url];
    
    // Hint to next step
    if ([self getAppRunCount] < 5 && [self getNextStepRunCondition])
    {
        if (_popTipView)
        {
            NSString *hint = GBLocalizedString(@"UsageNextHint");
            _popTipView.message = hint;
            [_popTipView autoDismissAnimated:YES atTimeInterval:5.0];
            [_popTipView presentPointingAtBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
        }
    }
}

#pragma mark - IGAssetsPickerDelegate
- (void)IGAssetsPickerFinishCroppingToAsset:(id)asset
{
    if ([asset isKindOfClass:[UIImage class]]) // photo
    {
//        UIImage *image = (UIImage *)asset;
    }
    else if([asset isKindOfClass:[AVAsset class]]) // video
    {
        NSURL *url = ((AVURLAsset *)asset).URL;
        [self setPickedVideo:url checkVideoLength:NO];
    }
}

- (void)IGAssetsPickerGetCropRegion:(CGRect)rect withAlAsset:(id)asset
{
}

#pragma mark - pickVideoFromInstagramPhotosAlbum
- (void)pickVideoFromInstagramPhotosAlbum
{
    IGAssetsPickerViewController *picker = [[IGAssetsPickerViewController alloc] init];
    picker.delegate = self;
    picker.mediaType = OnlyVideos;
    picker.videoMaxLength = MaxVideoLength;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - pickBackgroundVideoFromPhotosAlbum
- (void)pickBackgroundVideoFromPhotosAlbum
{
    [self pickVideoFromPhotoAlbum];
}

- (void)pickVideoFromPhotoAlbum
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        // Only movie
        NSArray* availableMedia = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        picker.mediaTypes = [NSArray arrayWithObject:availableMedia[1]];
    }
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - pickBackgroundVideoFromCamera
- (void)pickBackgroundVideoFromCamera
{
    [self pickVideoFromCamera];
}

- (void)pickVideoFromCamera
{
    CaptureViewController *captureVC = [[CaptureViewController alloc] init];
    [captureVC setCallback:^(BOOL success, id result)
     {
         if (success)
         {
             NSURL *fileURL = result;
             [self setPickedVideo:fileURL checkVideoLength:NO];
         }
         else
         {
             NSLog(@"Video Picker Failed: %@", result);
         }
     }];
    
    [self presentViewController:captureVC animated:YES completion:^{
        NSLog(@"PickVideo present");
    }];
}

#pragma mark - getNextStepCondition
- (BOOL)getNextStepRunCondition
{
    BOOL result = TRUE;
    switch (_mirrorType)
    {
        case kMirrorLeftRightMirror:
        {
            if (!_videoPickURLHorizontal)
            {
                result = FALSE;
            }
            break;
        }
        case kMirrorUpDownReflection:
        {
            if (!_videoPickURLVertical)
            {
                result = FALSE;
            }
            break;
        }
        case kMirror4Square:
        {
            if (!_videoPickURLSquareLeftTop || !_videoPickURLSquareRightTop || !_videoPickURLSquareLeftBottom || !_videoPickURLSquareRightBottom)
            {
                result = FALSE;
            }
            break;
        }
        default:
            break;
    }

    return result;
}

#pragma mark - pickMusicFromCustom
- (void)pickMusicFromCustom
{
    if (![self getNextStepRunCondition])
    {
        NSString *message = nil;
        if (_mirrorType == kMirror4Square)
        {
            message = GBLocalizedString(@"Square4VideoIsEmptyHint");
        }
        else
        {
            message = GBLocalizedString(@"VideoIsEmptyHint");
        }
        
        showAlertMessage(message, nil);
        return;
    }
    
    AudioViewController *audioController = [[AudioViewController alloc] init];
    [audioController setSeletedRowBlock: ^(BOOL success, id result) {
        
        if (success && [result isKindOfClass:[NSNumber class]])
        {
            NSInteger index = [result integerValue];
            NSLog(@"pickAudio result: %ld", (long)index);
            
            if (index != NSNotFound)
            {
                NSArray *allAudios = [NSArray arrayWithObjects:
                                      [NSDictionary dictionaryWithObjectsAndKeys:GBLocalizedString(@"Apple"), @"song", @"Apple.mp3", @"url", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:GBLocalizedString(@"TheMoodOfLove"), @"song", @"Love Paradise.mp3", @"url", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:GBLocalizedString(@"LeadMeOn"), @"song", @"Lead Me On.mp3", @"url", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:GBLocalizedString(@"Butterfly"), @"song", @"Butterfly.mp3", @"url", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:GBLocalizedString(@"ALittleKiss"), @"song", @"A Little Kiss.mp3", @"url", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:GBLocalizedString(@"ByeByeSunday"), @"song", @"Bye Bye Sunday.mp3", @"url", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:GBLocalizedString(@"ComeWithMe"), @"song", @"Come With Me.mp3", @"url", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:GBLocalizedString(@"DolphinTango"), @"song", @"Dolphin Tango.mp3", @"url", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:GBLocalizedString(@"IDo"), @"song", @"I Do.mp3", @"url", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:GBLocalizedString(@"LetMeKnow"), @"song", @"Let Me Know.mp3", @"url", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:GBLocalizedString(@"SwingDance"), @"song", @"Swing Dance.mp3", @"url", nil],
                                      
                                      nil];
                NSDictionary *item = [allAudios objectAtIndex:index];
                NSString *file = [item objectForKey:@"url"];
                _audioPickFile = file;
            }
            else
            {
                _audioPickFile = nil;
            }
            
            // Convert
            [self handleConvert];
        }
    }];
    
    [self.navigationController pushViewController:audioController animated:NO];
}

#pragma mark - Default Setting
- (void)defaultVideoSetting:(NSURL *)url
{
    [self showVideoPlayView:YES];
    
    // Setting
    switch (_videoPositionType)
    {
        case kPositionHorizontal:
        {
             [self playDemoVideo:[url absoluteString] withinVideoPlayerController:_videoPlayerControllerHorizontal];
            break;
        }
        case kPositionVertical:
        {
             [self playDemoVideo:[url absoluteString] withinVideoPlayerController:_videoPlayerControllerVertical];
            break;
        }
        case kPositionSquareLeftBottom:
        {
             [self playDemoVideo:[url absoluteString] withinVideoPlayerController:_videoPlayerControllerSquareLeftBottom];
            break;
        }
        case kPositionSquareLeftTop:
        {
             [self playDemoVideo:[url absoluteString] withinVideoPlayerController:_videoPlayerControllerSquareLeftTop];
            break;
        }
        case kPositionSquareRightBottom:
        {
             [self playDemoVideo:[url absoluteString] withinVideoPlayerController:_videoPlayerControllerSquareRightBottom];
            break;
        }
        case kPositionSquareRightTop:
        {
             [self playDemoVideo:[url absoluteString] withinVideoPlayerController:_videoPlayerControllerSquareRightTop];
            break;
        }
        default:
            break;
    }
}

#pragma mark - playDemoVideo
- (void)playDemoVideo:(NSString*)inputVideoPath withinVideoPlayerController:(PBJVideoPlayerController*)videoPlayerController
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        videoPlayerController.videoPath = inputVideoPath;
        [videoPlayerController playFromBeginning];
    });
}

- (void)stopAllVideo
{
    if (_videoPlayerControllerHorizontal.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerControllerHorizontal stop];
    }
    
    if (_videoPlayerControllerVertical.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerControllerVertical stop];
    }
    
    if (_videoPlayerControllerSquareLeftBottom.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerControllerSquareLeftBottom stop];
    }
    
    if (_videoPlayerControllerSquareLeftTop.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerControllerSquareLeftTop stop];
    }
    
    if (_videoPlayerControllerSquareRightBottom.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerControllerSquareRightBottom stop];
    }
    
    if (_videoPlayerControllerSquareRightTop.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerControllerSquareRightTop stop];
    }
}

#pragma mark - Show/Hide
- (void)showVideoPlayView:(BOOL)show
{
    if (show)
    {
        switch (_videoPositionType)
        {
            case kPositionHorizontal:
            {
                _videoContentViewHorizontal.hidden = NO;
                _closeVideoPlayerButtonHorizontal.hidden = NO;
                
                _videoViewHorizontal.hidden = YES;
                break;
            }
            case kPositionVertical:
            {
                _videoContentViewVertical.hidden = NO;
                _closeVideoPlayerButtonVertical.hidden = NO;
                
                _videoViewVertical.hidden = YES;
                break;
            }
            case kPositionSquareLeftBottom:
            {
                _videoPlayerControllerSquareLeftBottom.view.hidden = NO;
                _closeVideoPlayerButtonSquareLeftBottom.hidden = NO;
                
                _videoViewSquareLeftBottom.hidden = YES;
                break;
            }
            case kPositionSquareLeftTop:
            {
                _videoPlayerControllerSquareLeftTop.view.hidden = NO;
                _closeVideoPlayerButtonSquareLeftTop.hidden = NO;
                
                _videoViewSquareLeftTop.hidden = YES;
                break;
            }
            case kPositionSquareRightBottom:
            {
                _videoPlayerControllerSquareRightBottom.view.hidden = NO;
                _closeVideoPlayerButtonSquareRightBottom.hidden = NO;
                
                _videoViewSquareRightBottom.hidden = YES;
                break;
            }
            case kPositionSquareRightTop:
            {
                _videoPlayerControllerSquareRightTop.view.hidden = NO;
                _closeVideoPlayerButtonSquareRightTop.hidden = NO;
                
                _videoViewSquareRightTop.hidden = YES;
                break;
            }
            default:
                break;
        }
        
        if (_mirrorType == kMirror4Square)
        {
            [_squareParentView bringSubviewToFront:_closeVideoPlayerButtonSquareLeftTop];
            [_squareParentView bringSubviewToFront:_closeVideoPlayerButtonSquareRightTop];
            [_squareParentView bringSubviewToFront:_closeVideoPlayerButtonSquareLeftBottom];
            [_squareParentView bringSubviewToFront:_closeVideoPlayerButtonSquareRightBottom];
            [_squareParentView setNeedsDisplay];
        }
    }
    else
    {
        [self stopAllVideo];
        
        switch (_videoPositionType)
        {
            case kPositionHorizontal:
            {
                _videoViewHorizontal.hidden = NO;
                
                _videoContentViewHorizontal.hidden = YES;
                _closeVideoPlayerButtonHorizontal.hidden = YES;
                break;
            }
            case kPositionVertical:
            {
                _videoViewVertical.hidden = NO;
                
                _videoContentViewVertical.hidden = YES;
                _closeVideoPlayerButtonVertical.hidden = YES;
                break;
            }
            case kPositionSquareLeftBottom:
            {
                _videoViewSquareLeftBottom.hidden = NO;
                
                _videoPlayerControllerSquareLeftBottom.view.hidden = YES;
                _closeVideoPlayerButtonSquareLeftBottom.hidden = YES;
                break;
            }
            case kPositionSquareLeftTop:
            {
                _videoViewSquareLeftTop.hidden = NO;
                
                _videoPlayerControllerSquareLeftTop.view.hidden = YES;
                _closeVideoPlayerButtonSquareLeftTop.hidden = YES;
                break;
            }
            case kPositionSquareRightBottom:
            {
                _videoViewSquareRightBottom.hidden = NO;
                
                _videoPlayerControllerSquareRightBottom.view.hidden = YES;
                _closeVideoPlayerButtonSquareRightBottom.hidden = YES;
                break;
            }
            case kPositionSquareRightTop:
            {
                _videoViewSquareRightTop.hidden = NO;
                
                _videoPlayerControllerSquareRightTop.view.hidden = YES;
                _closeVideoPlayerButtonSquareRightTop.hidden = YES;
                break;
            }
            default:
                break;
        }
        
        if (_mirrorType == kMirror4Square)
        {
            [_squareParentView bringSubviewToFront:_closeVideoPlayerButtonSquareLeftTop];
            [_squareParentView bringSubviewToFront:_closeVideoPlayerButtonSquareRightTop];
            [_squareParentView bringSubviewToFront:_closeVideoPlayerButtonSquareLeftBottom];
            [_squareParentView bringSubviewToFront:_closeVideoPlayerButtonSquareRightBottom];
            [_squareParentView setNeedsDisplay];
        }
    }
}

#pragma mark - View LifeCycle
- (void)createRecommendAppView
{
    CGFloat statusBarHeight = 0; //iOS7AddStatusHeight;
    CGFloat navHeight = 0; //CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat height = 30;
    UIView *recommendAppView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - height - navHeight - statusBarHeight, CGRectGetWidth(self.view.frame), height)];
    [recommendAppView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:recommendAppView];
    
    [self createRecommendAppButtons:recommendAppView];
    
    // Demo button
    CGFloat width = 60;
    _demoButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2 - width/2, CGRectGetHeight(self.view.frame) - width, width, width)];
    UIImage *image = [UIImage imageNamed:@"demo"];
    [_demoButton setImage:image forState:UIControlStateNormal];
    [_demoButton addTarget:self action:@selector(handleDemoButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_demoButton];
}

- (void)createHorizontalView
{
    _horizontalParentView = [[UIView alloc] initWithFrame:self.view.bounds];
    _horizontalParentView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_horizontalParentView];
    
    [self createHorizontalContentView:_horizontalParentView];
    [self createHorizontalVideoPlayView:_horizontalParentView];
}

- (void)createVerticalView
{
    _verticalParentView = [[UIView alloc] initWithFrame:self.view.bounds];
    _verticalParentView.backgroundColor = [UIColor clearColor];
    _verticalParentView.hidden = YES;
    [self.view addSubview:_verticalParentView];
    
    [self createVerticalContentView:_verticalParentView];
    [self createVerticalVideoPlayView:_verticalParentView];
}

- (void)createSquareView
{
    _squareParentView = [[UIView alloc] initWithFrame:self.view.bounds];
    _squareParentView.backgroundColor = [UIColor clearColor];
    _squareParentView.hidden = YES;
    [self.view addSubview:_squareParentView];
    
    [self createSquareContentView:_squareParentView];
    [self createSquareVideoPlayView:_squareParentView];
}

- (void)createSquareContentView:(UIView *)parentView
{
    CGFloat statusBarHeight = 0; //iOS7AddStatusHeight;
    CGFloat navHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat gap = 15, len = MIN((CGRectGetHeight(self.view.frame) - navHeight - statusBarHeight - 2*gap), (CGRectGetWidth(self.view.frame) - navHeight - statusBarHeight - 2*gap));
    _captureContentViewSquare =  [[UIScrollView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - len/2, CGRectGetMidY(self.view.frame) - len/2, len, len)];
    [_captureContentViewSquare setBackgroundColor:[UIColor clearColor]];
    [parentView addSubview:_captureContentViewSquare];
    
    // 1.
    _videoViewSquareLeftTop = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(_captureContentViewSquare.frame), CGRectGetMinY(_captureContentViewSquare.frame), CGRectGetWidth(_captureContentViewSquare.bounds)/2, CGRectGetHeight(_captureContentViewSquare.bounds)/2)];
    [_videoViewSquareLeftTop setBackgroundColor:[UIColor clearColor]];
    _videoViewSquareLeftTop.tag = kPositionSquareLeftTop;
    
    _videoViewSquareLeftTop.layer.cornerRadius = 5;
    _videoViewSquareLeftTop.layer.masksToBounds = YES;
    _videoViewSquareLeftTop.layer.borderWidth = 1.0;
    _videoViewSquareLeftTop.layer.borderColor = [UIColor whiteColor].CGColor;
    
    UIImage *addFileImage = [UIImage imageNamed:@"Video_Add"];
    [_videoViewSquareLeftTop setImage:addFileImage forState:UIControlStateNormal];
    [_videoViewSquareLeftTop addTarget:self action:@selector(showCustomActionSheetByView:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_videoViewSquareLeftTop];
    
    // 2.
    _videoViewSquareRightTop = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMidX(_captureContentViewSquare.frame), CGRectGetMinY(_captureContentViewSquare.frame), CGRectGetWidth(_captureContentViewSquare.bounds)/2, CGRectGetHeight(_captureContentViewSquare.bounds)/2)];
    [_videoViewSquareRightTop setBackgroundColor:[UIColor clearColor]];
    _videoViewSquareRightTop.tag = kPositionSquareRightTop;
    
    _videoViewSquareRightTop.layer.cornerRadius = 5;
    _videoViewSquareRightTop.layer.masksToBounds = YES;
    _videoViewSquareRightTop.layer.borderWidth = 1.0;
    _videoViewSquareRightTop.layer.borderColor = [UIColor whiteColor].CGColor;
    
    [_videoViewSquareRightTop setImage:addFileImage forState:UIControlStateNormal];
    [_videoViewSquareRightTop addTarget:self action:@selector(showCustomActionSheetByView:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_videoViewSquareRightTop];
    
    // 3.
    _videoViewSquareLeftBottom = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(_captureContentViewSquare.frame), CGRectGetMidY(_captureContentViewSquare.frame), CGRectGetWidth(_captureContentViewSquare.bounds)/2, CGRectGetHeight(_captureContentViewSquare.bounds)/2)];
    [_videoViewSquareLeftBottom setBackgroundColor:[UIColor clearColor]];
    _videoViewSquareLeftBottom.tag = kPositionSquareLeftBottom;
    
    _videoViewSquareLeftBottom.layer.cornerRadius = 5;
    _videoViewSquareLeftBottom.layer.masksToBounds = YES;
    _videoViewSquareLeftBottom.layer.borderWidth = 1.0;
    _videoViewSquareLeftBottom.layer.borderColor = [UIColor whiteColor].CGColor;
    
    [_videoViewSquareLeftBottom setImage:addFileImage forState:UIControlStateNormal];
    [_videoViewSquareLeftBottom addTarget:self action:@selector(showCustomActionSheetByView:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_videoViewSquareLeftBottom];
    
    // 4.
    _videoViewSquareRightBottom = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMidX(_captureContentViewSquare.frame), CGRectGetMidY(_captureContentViewSquare.frame), CGRectGetWidth(_captureContentViewSquare.bounds)/2, CGRectGetHeight(_captureContentViewSquare.bounds)/2)];
    [_videoViewSquareRightBottom setBackgroundColor:[UIColor clearColor]];
    _videoViewSquareRightBottom.tag = kPositionSquareRightBottom;
    
    _videoViewSquareRightBottom.layer.cornerRadius = 5;
    _videoViewSquareRightBottom.layer.masksToBounds = YES;
    _videoViewSquareRightBottom.layer.borderWidth = 1.0;
    _videoViewSquareRightBottom.layer.borderColor = [UIColor whiteColor].CGColor;
    
    [_videoViewSquareRightBottom setImage:addFileImage forState:UIControlStateNormal];
    [_videoViewSquareRightBottom addTarget:self action:@selector(showCustomActionSheetByView:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_videoViewSquareRightBottom];
}

- (void)createSquareVideoPlayView:(UIView *)parentView
{
    _videoContentViewSquare =  [[UIScrollView alloc] initWithFrame:_captureContentViewSquare.frame];
    [_videoContentViewSquare setBackgroundColor:[UIColor clearColor]];
    [parentView addSubview:_videoContentViewSquare];
    
    // 1.
    _videoPlayerControllerSquareLeftTop = [[PBJVideoPlayerController alloc] init];
    _videoPlayerControllerSquareLeftTop.delegate = self;
    _videoPlayerControllerSquareLeftTop.view.frame = CGRectMake(0, 0, CGRectGetWidth(_videoContentViewSquare.bounds)/2, CGRectGetHeight(_videoContentViewSquare.bounds)/2);
    _videoPlayerControllerSquareLeftTop.view.clipsToBounds = YES;
    
    [self addChildViewController:_videoPlayerControllerSquareLeftTop];
    [_videoContentViewSquare addSubview:_videoPlayerControllerSquareLeftTop.view];
    
    _playButtonSquareLeftTop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button"]];
    _playButtonSquareLeftTop.center = _videoPlayerControllerSquareLeftTop.view.center;
    [_videoPlayerControllerSquareLeftTop.view addSubview:_playButtonSquareLeftTop];
    
    // Close video player
    UIImage *imageClose = [UIImage imageNamed:@"close"];
    CGFloat width = 50;
    _closeVideoPlayerButtonSquareLeftTop = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(_videoViewSquareLeftTop.frame) - width/2, CGRectGetMinY(_videoViewSquareLeftTop.frame) - width/2, width, width)];
    _closeVideoPlayerButtonSquareLeftTop.center = _videoViewSquareLeftTop.frame.origin;
    [_closeVideoPlayerButtonSquareLeftTop setImage:imageClose forState:(UIControlStateNormal)];
    [_closeVideoPlayerButtonSquareLeftTop addTarget:self action:@selector(handleCloseVideo:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_closeVideoPlayerButtonSquareLeftTop];
    
    _closeVideoPlayerButtonSquareLeftTop.tag = kPositionSquareLeftTop;
    _closeVideoPlayerButtonSquareLeftTop.hidden = YES;
    
    // 2.
    _videoPlayerControllerSquareRightTop = [[PBJVideoPlayerController alloc] init];
    _videoPlayerControllerSquareRightTop.delegate = self;
    _videoPlayerControllerSquareRightTop.view.frame = CGRectMake(CGRectGetWidth(_videoContentViewSquare.bounds)/2, 0, CGRectGetWidth(_videoContentViewSquare.bounds)/2, CGRectGetHeight(_videoContentViewSquare.bounds)/2);
    _videoPlayerControllerSquareRightTop.view.clipsToBounds = YES;
    
    [self addChildViewController:_videoPlayerControllerSquareRightTop];
    [_videoContentViewSquare addSubview:_videoPlayerControllerSquareRightTop.view];
    
    _playButtonSquareRightTop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button"]];
    _playButtonSquareRightTop.center = _videoPlayerControllerSquareRightTop.view.center;
    [_videoPlayerControllerSquareRightTop.view addSubview:_playButtonSquareRightTop];
    
    // Close video player
    _closeVideoPlayerButtonSquareRightTop = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(_videoViewSquareRightTop.frame) - width/2, CGRectGetMinY(_videoViewSquareRightTop.frame) - width/2, width, width)];
    _closeVideoPlayerButtonSquareRightTop.center = _videoViewSquareRightTop.frame.origin;
    [_closeVideoPlayerButtonSquareRightTop setImage:imageClose forState:(UIControlStateNormal)];
    [_closeVideoPlayerButtonSquareRightTop addTarget:self action:@selector(handleCloseVideo:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_closeVideoPlayerButtonSquareRightTop];
    
    _closeVideoPlayerButtonSquareRightTop.tag = kPositionSquareRightTop;
    _closeVideoPlayerButtonSquareRightTop.hidden = YES;

    // 3.
    _videoPlayerControllerSquareLeftBottom = [[PBJVideoPlayerController alloc] init];
    _videoPlayerControllerSquareLeftBottom.delegate = self;
    _videoPlayerControllerSquareLeftBottom.view.frame = CGRectMake(0, CGRectGetHeight(_videoContentViewSquare.bounds)/2, CGRectGetWidth(_videoContentViewSquare.bounds)/2, CGRectGetHeight(_videoContentViewSquare.bounds)/2);
    _videoPlayerControllerSquareLeftBottom.view.clipsToBounds = YES;
    
    [self addChildViewController:_videoPlayerControllerSquareLeftBottom];
    [_videoContentViewSquare addSubview:_videoPlayerControllerSquareLeftBottom.view];
    
    _playButtonSquareLeftBottom = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button"]];
    _playButtonSquareLeftBottom.center = _videoPlayerControllerSquareLeftBottom.view.center;
    [_videoPlayerControllerSquareLeftBottom.view addSubview:_playButtonSquareLeftBottom];
    
    // Close video player
    _closeVideoPlayerButtonSquareLeftBottom = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(_videoViewSquareLeftBottom.frame) - width/2, CGRectGetMinY(_videoViewSquareLeftBottom.frame) - width/2, width, width)];
    _closeVideoPlayerButtonSquareLeftBottom.center = _videoViewSquareLeftBottom.frame.origin;
    [_closeVideoPlayerButtonSquareLeftBottom setImage:imageClose forState:(UIControlStateNormal)];
    [_closeVideoPlayerButtonSquareLeftBottom addTarget:self action:@selector(handleCloseVideo:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_closeVideoPlayerButtonSquareLeftBottom];
    
    _closeVideoPlayerButtonSquareLeftBottom.tag = kPositionSquareLeftBottom;
    _closeVideoPlayerButtonSquareLeftBottom.hidden = YES;
    
    // 4.
    _videoPlayerControllerSquareRightBottom = [[PBJVideoPlayerController alloc] init];
    _videoPlayerControllerSquareRightBottom.delegate = self;
    _videoPlayerControllerSquareRightBottom.view.frame = CGRectMake(CGRectGetWidth(_videoContentViewSquare.bounds)/2, CGRectGetHeight(_videoContentViewSquare.bounds)/2, CGRectGetWidth(_videoContentViewSquare.bounds)/2, CGRectGetHeight(_videoContentViewSquare.bounds)/2);
    _videoPlayerControllerSquareRightBottom.view.clipsToBounds = YES;
    
    [self addChildViewController:_videoPlayerControllerSquareRightBottom];
    [_videoContentViewSquare addSubview:_videoPlayerControllerSquareRightBottom.view];
    
    _playButtonSquareRightBottom = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button"]];
    _playButtonSquareRightBottom.center = _videoPlayerControllerSquareRightBottom.view.center;
    [_videoPlayerControllerSquareRightBottom.view addSubview:_playButtonSquareRightBottom];
    
    // Close video player
    _closeVideoPlayerButtonSquareRightBottom = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(_videoViewSquareRightBottom.frame) - width/2, CGRectGetMinY(_videoViewSquareRightBottom.frame) - width/2, width, width)];
    _closeVideoPlayerButtonSquareRightBottom.center = _videoViewSquareRightBottom.frame.origin;
    [_closeVideoPlayerButtonSquareRightBottom setImage:imageClose forState:(UIControlStateNormal)];
    [_closeVideoPlayerButtonSquareRightBottom addTarget:self action:@selector(handleCloseVideo:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_closeVideoPlayerButtonSquareRightBottom];
    
    _closeVideoPlayerButtonSquareRightBottom.tag = kPositionSquareRightBottom;
    _closeVideoPlayerButtonSquareRightBottom.hidden = YES;
}

- (void)createHorizontalContentView:(UIView *)parentView
{
    CGFloat statusBarHeight = 0; //iOS7AddStatusHeight;
    CGFloat navHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat gap = 15, len = MIN((CGRectGetHeight(self.view.frame) - navHeight - statusBarHeight - 2*gap), (CGRectGetWidth(self.view.frame) - navHeight - statusBarHeight - 2*gap));
    _captureContentViewHorizontal =  [[UIScrollView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - len/2, CGRectGetMidY(self.view.frame) - len/2, len, len)];
    [_captureContentViewHorizontal setBackgroundColor:[UIColor clearColor]];
    [parentView addSubview:_captureContentViewHorizontal];
    
    _videoViewHorizontal = [[UIButton alloc] initWithFrame:_captureContentViewHorizontal.frame];
    [_videoViewHorizontal setBackgroundColor:[UIColor clearColor]];
    _videoViewHorizontal.tag = kPositionHorizontal;
    
    _videoViewHorizontal.layer.cornerRadius = 5;
    _videoViewHorizontal.layer.masksToBounds = YES;
    _videoViewHorizontal.layer.borderWidth = 1.0;
    _videoViewHorizontal.layer.borderColor = [UIColor whiteColor].CGColor;
    
    UIImage *addFileImage = [UIImage imageNamed:@"Video_Add"];
    [_videoViewHorizontal setImage:addFileImage forState:UIControlStateNormal];
    [_videoViewHorizontal addTarget:self action:@selector(showCustomActionSheetByView:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_videoViewHorizontal];
}

- (void)createHorizontalVideoPlayView:(UIView *)parentView
{
    _videoContentViewHorizontal =  [[UIScrollView alloc] initWithFrame:_captureContentViewHorizontal.frame];
    [_videoContentViewHorizontal setBackgroundColor:[UIColor clearColor]];
    [parentView addSubview:_videoContentViewHorizontal];
    
    // Video player
    _videoPlayerControllerHorizontal = [[PBJVideoPlayerController alloc] init];
    _videoPlayerControllerHorizontal.delegate = self;
    _videoPlayerControllerHorizontal.view.frame = _videoViewHorizontal.bounds;
    _videoPlayerControllerHorizontal.view.clipsToBounds = YES;
    
    [self addChildViewController:_videoPlayerControllerHorizontal];
    [_videoContentViewHorizontal addSubview:_videoPlayerControllerHorizontal.view];
    
    _playButtonHorizontal = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button"]];
    _playButtonHorizontal.center = _videoPlayerControllerHorizontal.view.center;
    [_videoPlayerControllerHorizontal.view addSubview:_playButtonHorizontal];
    
    // Close video player
    UIImage *imageClose = [UIImage imageNamed:@"close"];
    CGFloat width = 50;
    _closeVideoPlayerButtonHorizontal = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(_videoContentViewHorizontal.frame) - width/2, CGRectGetMinY(_videoContentViewHorizontal.frame) - width/2, width, width)];
    _closeVideoPlayerButtonHorizontal.center = _captureContentViewHorizontal.frame.origin;
    [_closeVideoPlayerButtonHorizontal setImage:imageClose forState:(UIControlStateNormal)];
    [_closeVideoPlayerButtonHorizontal addTarget:self action:@selector(handleCloseVideo:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_closeVideoPlayerButtonHorizontal];
    
    _closeVideoPlayerButtonHorizontal.tag = kPositionHorizontal;
    _closeVideoPlayerButtonHorizontal.hidden = YES;
}

- (void)createVerticalContentView:(UIView *)parentView
{
    CGFloat statusBarHeight = 0; //iOS7AddStatusHeight;
    CGFloat navHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat gap = 15, len = MIN((CGRectGetHeight(self.view.frame) - navHeight - statusBarHeight - 2*gap), (CGRectGetWidth(self.view.frame) - navHeight - statusBarHeight - 2*gap));
    _captureContentViewVertical =  [[UIScrollView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - len/2, CGRectGetMidY(self.view.frame) - len/2, len, len)];
    [_captureContentViewVertical setBackgroundColor:[UIColor clearColor]];
    [parentView addSubview:_captureContentViewVertical];
    
    _videoViewVertical = [[UIButton alloc] initWithFrame:_captureContentViewVertical.frame];
    [_videoViewVertical setBackgroundColor:[UIColor clearColor]];
    _videoViewVertical.tag = kPositionVertical;
    
    _videoViewVertical.layer.cornerRadius = 5;
    _videoViewVertical.layer.masksToBounds = YES;
    _videoViewVertical.layer.borderWidth = 1.0;
    _videoViewVertical.layer.borderColor = [UIColor whiteColor].CGColor;
    
    UIImage *addFileImage = [UIImage imageNamed:@"Video_Add"];
    [_videoViewVertical setImage:addFileImage forState:UIControlStateNormal];
    [_videoViewVertical addTarget:self action:@selector(showCustomActionSheetByView:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_videoViewVertical];
}

- (void)createVerticalVideoPlayView:(UIView *)parentView
{
    _videoContentViewVertical =  [[UIScrollView alloc] initWithFrame:_captureContentViewVertical.frame];
    [_videoContentViewVertical setBackgroundColor:[UIColor clearColor]];
    [parentView addSubview:_videoContentViewVertical];
    
    // Video player 1
    _videoPlayerControllerVertical = [[PBJVideoPlayerController alloc] init];
    _videoPlayerControllerVertical.delegate = self;
    _videoPlayerControllerVertical.view.frame = _videoViewVertical.bounds;
    _videoPlayerControllerVertical.view.clipsToBounds = YES;
    
    [self addChildViewController:_videoPlayerControllerVertical];
    [_videoContentViewVertical addSubview:_videoPlayerControllerVertical.view];
    
    _playButtonVertical = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button"]];
    _playButtonVertical.center = _videoPlayerControllerVertical.view.center;
    [_videoPlayerControllerVertical.view addSubview:_playButtonVertical];
    
    // Close video player
    UIImage *imageClose = [UIImage imageNamed:@"close"];
    CGFloat width = 50;
    _closeVideoPlayerButtonVertical = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(_videoContentViewVertical.frame) - width/2, CGRectGetMinY(_videoContentViewVertical.frame) - width/2, width, width)];
    _closeVideoPlayerButtonVertical.center = _captureContentViewVertical.frame.origin;
    [_closeVideoPlayerButtonVertical setImage:imageClose forState:(UIControlStateNormal)];
    [_closeVideoPlayerButtonVertical addTarget:self action:@selector(handleCloseVideo:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_closeVideoPlayerButtonVertical];
    
    _closeVideoPlayerButtonVertical.tag = kPositionVertical;
    _closeVideoPlayerButtonVertical.hidden = YES;
}

- (void)createSegmentedControl
{
    _segmentedControl = [[NYSegmentedControl alloc] initWithItems:@[GBLocalizedString(@"Horizontal"), GBLocalizedString(@"Vertical"), GBLocalizedString(@"Square")]];
    [_segmentedControl addTarget:self action:@selector(segmentedControlSelected:) forControlEvents:UIControlEventValueChanged];
    _segmentedControl.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    _segmentedControl.segmentIndicatorBackgroundColor = [UIColor whiteColor];
    _segmentedControl.segmentIndicatorInset = 0.0f;
    _segmentedControl.titleTextColor = [UIColor lightGrayColor];
    _segmentedControl.selectedTitleTextColor = [UIColor darkGrayColor];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    _segmentedControl.usesSpringAnimations = YES;
#endif
    [_segmentedControl sizeToFit];
    
    CGFloat statusBarHeight = iOS7AddStatusHeight;
    CGFloat navHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat height = 50;
    _segmentedControl.center = CGPointMake(CGRectGetWidth(self.view.frame)/2, navHeight + statusBarHeight + height/2);
    [self.view addSubview:_segmentedControl];
    
    self.visibleParentView = _horizontalParentView;
    self.mirrorParentViews = @[_horizontalParentView, _verticalParentView, _squareParentView];
}

- (void)createNavigationBar
{
    NSString *fontName = GBLocalizedString(@"FontName");
    CGFloat fontSize = 20;
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0 green:0.7 blue:0.8 alpha:1];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [UIColor whiteColor], NSForegroundColorAttributeName,
                                                                     shadow,
                                                                     NSShadowAttributeName,
                                                                     [UIFont fontWithName:fontName size:fontSize], NSFontAttributeName,
                                                                     nil]];
    
    self.title = GBLocalizedString(@"VideoReflection");
}

- (void)createNavigationItem
{
    NSString *fontName = GBLocalizedString(@"FontName");
    CGFloat fontSize = 18;
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:GBLocalizedString(@"Next") style:UIBarButtonItemStylePlain target:self action:@selector(pickMusicFromCustom)];
    [rightItem setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont fontWithName:fontName size:fontSize]} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:GBLocalizedString(@"Settings") style:UIBarButtonItemStylePlain target:self action:@selector(showSettingsModal:)];
    [leftItem setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont fontWithName:fontName size:fontSize]} forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = leftItem;
}

- (void)createPopTipView
{
    NSArray *colorSchemes = [NSArray arrayWithObjects:
                             [NSArray arrayWithObjects:[NSNull null], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor colorWithRed:134.0/255.0 green:74.0/255.0 blue:110.0/255.0 alpha:1.0], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor darkGrayColor], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor lightGrayColor], [UIColor darkTextColor], nil],
                             nil];
    NSArray *colorScheme = [colorSchemes objectAtIndex:foo4random()*[colorSchemes count]];
    UIColor *backgroundColor = [colorScheme objectAtIndex:0];
    UIColor *textColor = [colorScheme objectAtIndex:1];
    
    NSString *hint = GBLocalizedString(@"UsageHint");
    _popTipView = [[CMPopTipView alloc] initWithMessage:hint];
    if (backgroundColor && ![backgroundColor isEqual:[NSNull null]])
    {
        _popTipView.backgroundColor = backgroundColor;
    }
    if (textColor && ![textColor isEqual:[NSNull null]])
    {
        _popTipView.textColor = textColor;
    }
    
    _popTipView.animation = arc4random() % 2;
    _popTipView.has3DStyle = NO;
    _popTipView.dismissTapAnywhere = YES;
    [_popTipView autoDismissAnimated:YES atTimeInterval:5.0];
    
    [_popTipView presentPointingAtView:_playButtonHorizontal inView:_horizontalParentView animated:YES];
//    [_popTipView presentPointingAtView:findRightNavBarItemView(self.navigationController.navigationBar) inView:self.navigationController.view animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sharebg3"]];
    
    _videoPickURLHorizontal = nil;
    _videoPickURLVertical = nil;
    _videoPickURLSquareLeftTop = nil;
    _videoPickURLSquareRightTop = nil;
    _videoPickURLSquareLeftBottom = nil;
    _videoPickURLSquareRightBottom = nil;
    _popTipView = nil;
    
    _mirrorType = kMirrorLeftRightMirror;
    _videoPositionType = kPositionHorizontal;
    
    [self createNavigationItem];
    
    [self createHorizontalView];
    [self createVerticalView];
    [self createSquareView];
    
    [self createSegmentedControl];
    [self createRecommendAppView];
    
    // Hint
    NSInteger appRunCount = [self getAppRunCount];
    if (appRunCount < 5)
    {
        [self createPopTipView];
    }
    
    if (appRunCount == 0)
    {
        [self setShouldDisplayDemoButton:YES];
    }
    else if (![self getShouldDisplayDemoButton])
    {
        _demoButton.hidden = YES;
    }
    
    [self addAppRunCount];
    
    [self showVideoPlayView:NO];
    
    // Delete temp files
    [self deleteTempDirectory];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self createNavigationBar];
    
    // Contace us
//    [self createContactUS];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if(self.currentPopoverController)
    {
        [self dismissCurrentPopover];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SegmentedControl Selected
- (void)segmentedControlSelected:(id)sender
{
    NYSegmentedControl *segControl = (NYSegmentedControl *)sender;
    NSLog(@"segmentedControlSelected: %lu", (unsigned long)segControl.selectedSegmentIndex);
    
    UIView *viewToShow = self.mirrorParentViews[segControl.selectedSegmentIndex];
    if (_visibleParentView == viewToShow)
    {
        return;
    }
    
    [self stopAllVideo];
    
    _visibleParentView.hidden = YES;
    viewToShow.hidden = NO;
    _visibleParentView = viewToShow;
    
    switch (segControl.selectedSegmentIndex)
    {
        case 0:
        {
            [_visibleParentView bringSubviewToFront:_videoViewHorizontal];
            
            [self setMirrorType:kMirrorLeftRightMirror];
            break;
        }
        case 1:
        {
            [_visibleParentView bringSubviewToFront:_videoViewVertical];
            
            [self setMirrorType:kMirrorUpDownReflection];
            break;
        }
        case 2:
        {
            [_visibleParentView bringSubviewToFront:_videoViewSquareLeftBottom];
            [_visibleParentView bringSubviewToFront:_videoViewSquareLeftTop];
            [_visibleParentView bringSubviewToFront:_videoViewSquareRightBottom];
            [_visibleParentView bringSubviewToFront:_videoViewSquareRightTop];
            
            [self setMirrorType:kMirror4Square];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Handle Event
- (void)handleDemoButton
{
    switch (_mirrorType)
    {
        case kMirrorLeftRightMirror:
        {
            NSString *demoVideoPath = getFilePath(DemoHorizontalVideoName);
            [self showDemoVideo:demoVideoPath];

            break;
        }
        case kMirrorUpDownReflection:
        {
            NSString *demoVideoPath = getFilePath(DemoVerticalVideoName);
            [self showDemoVideo:demoVideoPath];
            
            break;
        }
        case kMirror4Square:
        {
            NSString *demoVideoPath = getFilePath(DemoSquareVideoName);
            [self showDemoVideo:demoVideoPath];
            
            break;
        }
        default:
            break;
    }
}

- (void)handleConvert
{
    ProgressBarShowLoading(GBLocalizedString(@"Processing"));
    
    [[ExportEffects sharedInstance] setExportProgressBlock: ^(NSNumber *percentage) {
        
        // Export progress
        [self retrievingProgress:percentage title:GBLocalizedString(@"SavingVideo")];
    }];
    
    [[ExportEffects sharedInstance] setFinishVideoBlock: ^(BOOL success, id result) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (success)
            {
                ProgressBarDismissLoading(GBLocalizedString(@"Success"));
            }
            else
            {
                ProgressBarDismissLoading(GBLocalizedString(@"Failed"));
            }
            
            // Alert
            NSString *ok = GBLocalizedString(@"OK");
            [UIAlertView showWithTitle:nil
                               message:result
                     cancelButtonTitle:ok
                     otherButtonTitles:nil
                              tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                  if (buttonIndex == [alertView cancelButtonIndex])
                                  {
                                      NSLog(@"Alert Cancelled");
                                      
                                      [NSThread sleepForTimeInterval:0.5];
                                      
                                      // Demo result video
                                      if (!isStringEmpty([ExportEffects sharedInstance].filenameBlock()))
                                      {
                                          NSString *outputPath = [ExportEffects sharedInstance].filenameBlock();
                                          [self showDemoVideo:outputPath];
                                      }
                                  }
                              }];
            
            [self showVideoPlayView:TRUE];
        });
    }];
    
    [[ExportEffects sharedInstance] setMirrorType:_mirrorType];
    [self setMirrorType:_mirrorType];
    
    NSArray *videoFileArray = nil;
    switch (_mirrorType)
    {
        case kMirrorLeftRightMirror:
        {
            videoFileArray = [NSArray arrayWithObjects:[_videoPickURLHorizontal relativePath], nil];
            break;
        }
        case kMirrorUpDownReflection:
        {
            videoFileArray = [NSArray arrayWithObjects:[_videoPickURLVertical relativePath], nil];
            break;
        }
        case kMirror4Square:
        {
            videoFileArray = [NSArray arrayWithObjects:[_videoPickURLSquareLeftBottom relativePath], [_videoPickURLSquareRightBottom relativePath], [_videoPickURLSquareLeftTop relativePath], [_videoPickURLSquareRightTop relativePath], nil];
            break;
        }
        default:
            break;
    }
    
    if (!videoFileArray || [videoFileArray count] < 1)
    {
        NSLog(@"videoFileArray is empty.");
        return;
    }
    [[ExportEffects sharedInstance] addEffectToVideo:videoFileArray withAudioFilePath:getFilePath(_audioPickFile)];
}

- (void)handleCloseVideo:(UIView *)anchor
{
    if ([anchor isKindOfClass:[UIButton class]])
    {
        if (anchor.tag > 0)
        {
            _videoPositionType = anchor.tag;
            NSLog(@"handleCloseVideo videoPositionType: %ld", (unsigned long)_videoPositionType);
        }
    }
    
    [self showVideoPlayView:NO];
    
    switch (_videoPositionType)
    {
        case kPositionHorizontal:
        {
            [_videoPlayerControllerHorizontal clearView];
            _videoPickURLHorizontal = nil;
            break;
        }
        case kPositionVertical:
        {
            [_videoPlayerControllerVertical clearView];
            _videoPickURLVertical = nil;
            break;
        }
        case kPositionSquareLeftBottom:
        {
            [_videoPlayerControllerSquareLeftBottom clearView];
            _videoPickURLSquareLeftBottom = nil;
            break;
        }
        case kPositionSquareLeftTop:
        {
            [_videoPlayerControllerSquareLeftTop clearView];
            _videoPickURLSquareLeftTop = nil;
            break;
        }
        case kPositionSquareRightBottom:
        {
            [_videoPlayerControllerSquareRightBottom clearView];
            _videoPickURLSquareRightBottom = nil;
            break;
        }
        case kPositionSquareRightTop:
        {
            [_videoPlayerControllerSquareRightTop clearView];
            _videoPickURLSquareRightTop = nil;
            break;
        }
        default:
            break;
    }
}

#pragma mark - reCalc on the basis of video size & view size
- (void)reCalcVideoSize:(NSString *)videoPath
{
    CGFloat statusBarHeight = iOS7AddStatusHeight;
    CGSize sizeVideo = [self reCalcVideoViewSize:videoPath];
    if (_mirrorType == kMirrorLeftRightMirror)
    {
        _videoContentViewHorizontal.frame =  CGRectMake(CGRectGetMidX(self.view.frame) - sizeVideo.width/2, CGRectGetMidY(self.view.frame) - sizeVideo.height/2 + statusBarHeight, sizeVideo.width, sizeVideo.height);
        _videoPlayerControllerHorizontal.view.frame = _videoContentViewHorizontal.bounds;
        _playButtonHorizontal.center = _videoPlayerControllerHorizontal.view.center;
        _closeVideoPlayerButtonHorizontal.center = _videoContentViewHorizontal.frame.origin;
    }
    else if (_mirrorType == kMirrorUpDownReflection)
    {
        _videoContentViewVertical.frame =  CGRectMake(CGRectGetMidX(self.view.frame) - sizeVideo.width/2, CGRectGetMidY(self.view.frame) - sizeVideo.height/2 + statusBarHeight, sizeVideo.width, sizeVideo.height);
        _videoPlayerControllerVertical.view.frame = _videoContentViewVertical.bounds;
        _playButtonVertical.center = _videoPlayerControllerVertical.view.center;
        _closeVideoPlayerButtonVertical.center = _videoContentViewVertical.frame.origin;
    }
}

- (CGSize)reCalcVideoViewSize:(NSString *)videoPath
{
    CGSize resultSize = CGSizeZero;
    if (isStringEmpty(videoPath))
    {
        return resultSize;
    }
    
    UIImage *videoFrame = getImageFromVideoFrame(getFileURL(videoPath), kCMTimeZero);
    if (!videoFrame || videoFrame.size.height < 1 || videoFrame.size.width < 1)
    {
        return resultSize;
    }
    
    NSLog(@"reCalcVideoViewSize: %@, width: %f, height: %f", videoPath, videoFrame.size.width, videoFrame.size.height);
    
    CGFloat statusBarHeight = 0; //iOS7AddStatusHeight;
    CGFloat navHeight = 0; //CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat gap = 15;
    CGFloat height = CGRectGetHeight(self.view.frame) - navHeight - statusBarHeight - 2*gap;
    CGFloat width = CGRectGetWidth(self.view.frame) - 2*gap;
    if (height < width)
    {
        width = height;
    }
    else if (height > width)
    {
        height = width;
    }
    CGFloat videoHeight = videoFrame.size.height, videoWidth = videoFrame.size.width;
    CGFloat scaleRatio = videoHeight/videoWidth;
    CGFloat resultHeight = 0, resultWidth = 0;
    if (videoHeight <= height && videoWidth <= width)
    {
        resultHeight = videoHeight;
        resultWidth = videoWidth;
    }
    else if (videoHeight <= height && videoWidth > width)
    {
        resultWidth = width;
        resultHeight = height*scaleRatio;
    }
    else if (videoHeight > height && videoWidth <= width)
    {
        resultHeight = height;
        resultWidth = width/scaleRatio;
    }
    else
    {
        if (videoHeight < videoWidth)
        {
            resultWidth = width;
            resultHeight = height*scaleRatio;
        }
        else if (videoHeight == videoWidth)
        {
            resultWidth = width;
            resultHeight = height;
        }
        else
        {
            resultHeight = height;
            resultWidth = width/scaleRatio;
        }
    }
    
    resultSize = CGSizeMake(resultWidth, resultHeight);
    return resultSize;
}

#pragma mark - showDemoVideo
- (void)showDemoVideo:(NSString *)videoPath
{
    CGFloat statusBarHeight = iOS7AddStatusHeight;
    CGFloat navHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGSize size = [self reCalcVideoViewSize:videoPath];
    _demoVideoContentView =  [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - size.width/2, CGRectGetMidY(self.view.frame) - size.height/2 - navHeight - statusBarHeight, size.width, size.height)];
    [self.view addSubview:_demoVideoContentView];
    
    // Video player of destination
    _demoVideoPlayerController = [[PBJVideoPlayerController alloc] init];
    _demoVideoPlayerController.view.frame = _demoVideoContentView.bounds;
    _demoVideoPlayerController.view.clipsToBounds = YES;
    _demoVideoPlayerController.videoView.videoFillMode = AVLayerVideoGravityResizeAspect;
    _demoVideoPlayerController.delegate = self;
//    _demoVideoPlayerController.playbackLoops = YES;
    [_demoVideoContentView addSubview:_demoVideoPlayerController.view];
    
    _demoPlayButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button"]];
    _demoPlayButton.center = _demoVideoPlayerController.view.center;
    [_demoVideoPlayerController.view addSubview:_demoPlayButton];
    
    // Popup modal view
    [[KGModal sharedInstance] setCloseButtonType:KGModalCloseButtonTypeLeft];
    [[KGModal sharedInstance] showWithContentView:_demoVideoContentView andAnimated:YES];
    
    [self playDemoVideo:videoPath withinVideoPlayerController:_demoVideoPlayerController];
}

#pragma mark - getOutputFilePath
- (NSString*)getOutputFilePath
{
    NSString* mp4OutputFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"outputMovie.mov"];
    return mp4OutputFile;
}

#pragma mark - Progress callback
- (void)retrievingProgress:(id)progress title:(NSString *)text
{
    if (progress && [progress isKindOfClass:[NSNumber class]])
    {
        NSString *title = text ?text :GBLocalizedString(@"SavingVideo");
        NSString *currentPrecentage = [NSString stringWithFormat:@"%d%%", (int)([progress floatValue] * 100)];
        ProgressBarUpdateLoading(title, currentPrecentage);
    }
}

#pragma mark AppStore Open
- (void)showAppInAppStore:(NSString *)appId
{
    Class isAllow = NSClassFromString(@"SKStoreProductViewController");
    if (isAllow)
    {
        // > iOS6.0
        SKStoreProductViewController *sKStoreProductViewController = [[SKStoreProductViewController alloc] init];
        sKStoreProductViewController.delegate = self;
        [self presentViewController:sKStoreProductViewController
                           animated:YES
                         completion:nil];
        [sKStoreProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: appId}completionBlock:^(BOOL result, NSError *error)
         {
             if (error)
             {
                 NSLog(@"%@",error);
             }
             
         }];
    }
    else
    {
        // < iOS6.0
        NSString *appUrl = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/us/app/id%@?mt=8", appId];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appUrl]];
        
        //        UIWebView *callWebview = [[UIWebView alloc] init];
        //        NSURL *appURL =[NSURL URLWithString:appStore];
        //        [callWebview loadRequest:[NSURLRequest requestWithURL:appURL]];
        //        [self.view addSubview:callWebview];
    }
}

- (void)createRecommendAppButtons:(UIView *)containerView
{
    // Recommend App
    UIButton *beautyTime = [[UIButton alloc] init];
    [beautyTime setTitle:GBLocalizedString(@"BeautyTime")
                forState:UIControlStateNormal];
    
    UIButton *photoBeautify = [[UIButton alloc] init];
    [photoBeautify setTitle:GBLocalizedString(@"PhotoBeautify")
                   forState:UIControlStateNormal];
    
    [photoBeautify setTag:1];
    [beautyTime setTag:2];
    
    CGFloat gap = 0, height = 30, width = 80;
    CGFloat fontSize = 16;
    NSString *fontName = @"迷你简启体"; // GBLocalizedString(@"FontName");
    photoBeautify.frame =  CGRectMake(gap, gap, width, height);
    [photoBeautify.titleLabel setFont:[UIFont fontWithName:fontName size:fontSize]];
    [photoBeautify.titleLabel setTextAlignment:NSTextAlignmentLeft];
    [photoBeautify setTitleColor:kLightBlue forState:UIControlStateNormal];
    [photoBeautify addTarget:self action:@selector(recommendAppButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    beautyTime.frame =  CGRectMake(CGRectGetWidth(containerView.frame) - width - gap, gap, width, height);
    [beautyTime.titleLabel setFont:[UIFont fontWithName:fontName size:fontSize]];
    [beautyTime.titleLabel setTextAlignment:NSTextAlignmentRight];
    [beautyTime setTitleColor:kLightBlue forState:UIControlStateNormal];
    [beautyTime addTarget:self action:@selector(recommendAppButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [containerView addSubview:photoBeautify];
    [containerView addSubview:beautyTime];
}

- (void)recommendAppButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch (button.tag)
    {
        case 1:
        {
            // Photo Beautify
            [self showAppInAppStore:@"945682627"];
            break;
        }
        case 2:
        {
            // BeautyTime
            [self showAppInAppStore:@"1002437952"];
            break;
        }
        default:
            break;
    }
    
    [button setSelected:YES];
}

#pragma mark - SKStoreProductViewControllerDelegate
// Dismiss contorller
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - NSUserDefaults
#pragma mark - needDrawInnerVideoBorder
- (void)setShouldDisplayInnerBorder:(BOOL)shouldDisplay
{
    NSString *shouldDisplayInnerBorder = @"ShouldDisplayInnerBorder";
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    if (shouldDisplay)
    {
        [userDefaultes setBool:YES forKey:shouldDisplayInnerBorder];
    }
    else
    {
        [userDefaultes setBool:NO forKey:shouldDisplayInnerBorder];
    }
    
    [userDefaultes synchronize];
}

#pragma mark - setAppRunCount
- (void)addAppRunCount
{
    NSUInteger appRunCount = [self getAppRunCount];
    NSInteger limitCount = 5;
    if (appRunCount < limitCount)
    {
        ++appRunCount;
        NSString *appRunCountKey = @"AppRunCount";
        NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
        [userDefaultes setInteger:appRunCount forKey:appRunCountKey];
        [userDefaultes synchronize];
    }
}

#pragma mark - getAppRunCount
- (NSUInteger)getAppRunCount
{
    NSUInteger appRunCount = 0;
    NSString *appRunCountKey = @"AppRunCount";
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    if ([userDefaultes integerForKey:appRunCountKey])
    {
        appRunCount = [userDefaultes integerForKey:appRunCountKey];
    }
    
    NSLog(@"getAppRunCount: %lu", (unsigned long)appRunCount);
    return appRunCount;
}

#pragma mark - setMirrorType
- (void)setMirrorType:(MirrorType)type
{
    NSString *mirrorType = @"MirrorType";
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    [userDefaultes setInteger:type forKey:mirrorType];
    [userDefaultes synchronize];
    
    _mirrorType = type;
}

#pragma mark - ShouldDisplayDemoButton
- (BOOL)getShouldDisplayDemoButton
{
    NSString *shouldDisplayDemoButton = @"ShouldDisplayDemoButton";
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    BOOL shouldDisplay = [[userDefaultes objectForKey:shouldDisplayDemoButton] boolValue];
    NSLog(@"getShouldDisplayDemoButton: %@", shouldDisplay?@"Yes":@"No");
    
    if (shouldDisplay)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)setShouldDisplayDemoButton:(BOOL)shouldDisplay
{
    NSString *shouldDisplayDemoButton = @"ShouldDisplayDemoButton";
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    if (shouldDisplay)
    {
        [userDefaultes setBool:YES forKey:shouldDisplayDemoButton];
    }
    else
    {
        [userDefaultes setBool:NO forKey:shouldDisplayDemoButton];
    }
    [userDefaultes synchronize];
}

#pragma mark - ShouldDisplayWaveMirrorEffect
- (void)setShouldDisplayWaveMirrorEffect:(BOOL)shouldDisplay
{
    NSString *shouldDisplayWaveMirrorEffect = @"ShouldDisplayWaveMirrorEffect";
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    if (shouldDisplay)
    {
        [userDefaultes setBool:YES forKey:shouldDisplayWaveMirrorEffect];
    }
    else
    {
        [userDefaultes setBool:NO forKey:shouldDisplayWaveMirrorEffect];
    }
    [userDefaultes synchronize];
}

// Test
- (void)testFrames
{
    // Inner Video Frame
    NSString *RectFlag = @"arrayRect";
    CGFloat width = 100, gap = 30;
    CGRect innerVideoRect = CGRectMake(gap , gap, width, width);
    NSValue *rectValue = [NSValue valueWithCGRect:innerVideoRect];
    NSArray *arrayRect = [NSArray arrayWithObjects:rectValue, nil];
    NSData *dataRect = [NSKeyedArchiver archivedDataWithRootObject:arrayRect];
    [[NSUserDefaults standardUserDefaults] setObject:dataRect forKey:RectFlag];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
