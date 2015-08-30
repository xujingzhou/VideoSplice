//
//  VideoView.h
//  PictureInPicture
//
//  Created by Johnny Xu on 5/31/15.
//  Copyright (c) 2015 Future Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+Frame.h"
#import "CircleView.h"
#import "PBJVideoPlayerController.h"

@interface VideoView : UIView

@property (copy, nonatomic) GenericCallback deleteFinishBlock;
@property (nonatomic, strong) PBJVideoPlayerController *videoPlayerController1;

+ (void)setActiveVideoView:(VideoView*)view;

- (id)initWithFilePath:(NSString *)path withViewController:(UIViewController *)controller;

- (void)setScale:(CGFloat)scale;
- (void)setScale:(CGFloat)scaleX andScaleY:(CGFloat)scaleY;

- (CGRect)getInnerFrame;
- (CGFloat)getRotateAngle;
- (NSString *)getFilePath;

- (void)replayVideo;

@end
