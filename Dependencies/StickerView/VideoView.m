//
//  VideoView.m
//  PictureInPicture
//
//  Created by Johnny Xu on 5/31/15.
//  Copyright (c) 2015 Future Studio. All rights reserved.
//

#import "VideoView.h"

@implementation VideoView
{
    UIButton *_deleteButton;
    CircleView *_circleView;
    
    CGFloat _scale;
    CGFloat _arg;
    
    CGPoint _initialPoint;
    CGFloat _initialArg;
    CGFloat _initialScale;
    
    NSString *_filePath;
}

- (CGRect)getInnerFrame
{
    return [_videoPlayerController1.view.superview convertRect:_videoPlayerController1.view.frame toView:_videoPlayerController1.view.superview.superview];
}

- (CGFloat)getRotateAngle
{
    return _arg;
}

- (NSString *)getFilePath
{
    return _filePath;
}

+ (void)setActiveVideoView:(VideoView *)view
{
    static VideoView *activeView = nil;
    if(view != activeView)
    {
        [activeView setAvtive:NO];
        activeView = view;
        [activeView setAvtive:YES];
        
        [activeView.superview bringSubviewToFront:activeView];
    }
}

- (void)replayVideo
{
    if (_videoPlayerController1.playbackState == PBJVideoPlayerPlaybackStatePlaying || _videoPlayerController1.playbackState == PBJVideoPlayerPlaybackStatePaused)
    {
        [_videoPlayerController1 stop];
    }
    
    [_videoPlayerController1 playFromBeginning];
}

- (void)playVideo:(NSString*)inputVideoPath withinVideoPlayerController:(PBJVideoPlayerController*)videoPlayerController
{
    videoPlayerController.videoPath = inputVideoPath;
    [videoPlayerController playFromBeginning];
}

- (id)initWithFilePath:(NSString *)path withViewController:(UIViewController *)controller
{
    if (!isStringEmpty(path))
    {
        _filePath = path;
        
        return [self initWithVideoController:controller];
    }
    
    return nil;
}

- (id)initWithVideoController:(UIViewController *)controller
{
    CGFloat gap = 32, width = 100;
    self = [super initWithFrame:CGRectMake(0, 0, width + gap, width + gap)];
    
    if(self)
    {
        // Video player 1
        _videoPlayerController1 = [[PBJVideoPlayerController alloc] init];
        _videoPlayerController1.view.frame = CGRectMake(gap/2, gap/2, width, width);
        _videoPlayerController1.view.clipsToBounds = YES;
        
        [controller addChildViewController:_videoPlayerController1];
        [self addSubview:_videoPlayerController1.view];
        
        [self playVideo:_filePath withinVideoPlayerController:_videoPlayerController1];
        
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setImage:[UIImage imageNamed:@"turnoff_icon"] forState:UIControlStateNormal];
        _deleteButton.frame = CGRectMake(0, 0, 32, 32);
        _deleteButton.center = _videoPlayerController1.view.frame.origin;
        [_deleteButton addTarget:self action:@selector(pushedDeleteBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_deleteButton];
        
        _circleView = [[CircleView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        _circleView.center = CGPointMake(_videoPlayerController1.view.width + _videoPlayerController1.view.frame.origin.x, _videoPlayerController1.view.height + _videoPlayerController1.view.frame.origin.y);
        _circleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        _circleView.radius = 0.6;
        _circleView.color = [UIColor whiteColor];
        _circleView.borderColor = [UIColor redColor];
        _circleView.borderWidth = 2;
        [self addSubview:_circleView];
        
        _scale = 1;
        _arg = 0;
        
//        _imageView = [[UIView alloc] init];
//        _imageView.frame = _videoPlayerController1.view.frame;
//        _animatedLayer = [VideoAnimationLayer layerWithVideoFilePath:_filePath withFrame:_videoPlayerController1.view.frame];
//        [_imageView.layer addSublayer: _animatedLayer];
//        [self addSubview:_imageView];
//        [self sendSubviewToBack:_imageView];
        
        [self initGestures];
    }
    return self;
}

- (void)initGestures
{
    _videoPlayerController1.view.userInteractionEnabled = YES;
    [_videoPlayerController1.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTap:)]];
    [_videoPlayerController1.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPan:)]];
    [_circleView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(circleViewDidPan:)]];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* view = [super hitTest:point withEvent:event];
    
    if(view == self)
    {
        return nil;
    }
    return view;
}

- (void)pushedDeleteBtn:(id)sender
{
    if (_deleteFinishBlock)
    {
        _deleteFinishBlock(YES, self);
    }
    
    VideoView *nextTarget = nil;
    const NSInteger index = [self.superview.subviews indexOfObject:self];
    
    for(NSInteger i = index+1; i < self.superview.subviews.count; ++i)
    {
        UIView *view = [self.superview.subviews objectAtIndex:i];
        if([view isKindOfClass:[VideoView class]])
        {
            nextTarget = (VideoView*)view;
            break;
        }
    }
    
    if(!nextTarget)
    {
        for(NSInteger i = index-1; i >= 0; --i)
        {
            UIView *view = [self.superview.subviews objectAtIndex:i];
            if([view isKindOfClass:[VideoView class]])
            {
                nextTarget = (VideoView*)view;
                break;
            }
        }
    }
    
    [[self class] setActiveVideoView:nextTarget];
    [self removeFromSuperview];
}

- (void)setAvtive:(BOOL)active
{
    _deleteButton.hidden = !active;
    _circleView.hidden = !active;
    
    _videoPlayerController1.view.layer.borderColor = [UIColor redColor].CGColor;
    _videoPlayerController1.view.layer.borderWidth = (active) ? 1/_scale : 0;
}

- (void)setScale:(CGFloat)scaleX andScaleY:(CGFloat)scaleY
{
    _scale = MIN(scaleX, scaleY);
    self.transform = CGAffineTransformIdentity;
    _videoPlayerController1.view.transform = CGAffineTransformMakeScale(scaleX, scaleY);
    
    CGRect rct = self.frame;
    rct.origin.x += (rct.size.width - (_videoPlayerController1.view.width + 32)) / 2;
    rct.origin.y += (rct.size.height - (_videoPlayerController1.view.height + 32)) / 2;
    rct.size.width  = _videoPlayerController1.view.width + 32;
    rct.size.height = _videoPlayerController1.view.height + 32;
    self.frame = rct;
    
    _videoPlayerController1.view.center = CGPointMake(rct.size.width/2, rct.size.height/2);
    self.transform = CGAffineTransformMakeRotation(_arg);
    
    _videoPlayerController1.view.layer.borderWidth = 1/_scale;
    _videoPlayerController1.view.layer.cornerRadius = 3/_scale;
}

- (void)setScale:(CGFloat)scale
{
    [self setScale:scale andScaleY:scale];
}

- (void)viewDidTap:(UITapGestureRecognizer*)sender
{
    if (_videoPlayerController1.playbackState == PBJVideoPlayerPlaybackStatePaused || _videoPlayerController1.playbackState == PBJVideoPlayerPlaybackStateStopped)
    {
        [_videoPlayerController1 playFromCurrentTime];
    }
    else if (_videoPlayerController1.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerController1 pause];
    }
    
    [[self class] setActiveVideoView:self];
}

- (void)viewDidPan:(UIPanGestureRecognizer*)sender
{
    [[self class] setActiveVideoView:self];
    
    CGPoint p = [sender translationInView:self.superview];
    if(sender.state == UIGestureRecognizerStateBegan)
    {
        _initialPoint = self.center;
    }
    self.center = CGPointMake(_initialPoint.x + p.x, _initialPoint.y + p.y);
}

- (void)circleViewDidPan:(UIPanGestureRecognizer*)sender
{
    CGPoint p = [sender translationInView:self.superview];
    
    static CGFloat tmpR = 1;
    static CGFloat tmpA = 0;
    if(sender.state == UIGestureRecognizerStateBegan)
    {
        _initialPoint = [self.superview convertPoint:_circleView.center fromView:_circleView.superview];
        
        CGPoint p = CGPointMake(_initialPoint.x - self.center.x, _initialPoint.y - self.center.y);
        tmpR = sqrt(p.x*p.x + p.y*p.y);
        tmpA = atan2(p.y, p.x);
        
        _initialArg = _arg;
        _initialScale = _scale;
    }
    
    p = CGPointMake(_initialPoint.x + p.x - self.center.x, _initialPoint.y + p.y - self.center.y);
    CGFloat R = sqrt(p.x*p.x + p.y*p.y);
    CGFloat arg = atan2(p.y, p.x);
    
    _arg   = _initialArg + arg - tmpA;
    [self setScale:MAX(_initialScale * R / tmpR, 0.2)];
}

@end
