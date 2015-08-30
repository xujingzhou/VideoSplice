//
//  IGCropView.m
//  InstagramAssetsPicker
//
//  Created by JG on 2/3/15.
//  Copyright (c) 2015 JG. All rights reserved.
//

#import "IGCropView.h"
#import "GPUImage.h"

#define rad(angle) ((angle) / 180.0 * M_PI)


@interface IGCropView()<UIScrollViewDelegate>
{
    CGSize _imageSize;
    int _playState;//if is video(playing or pause) or image
    NSString * _type;
}

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) MPMoviePlayerController *videoPlayer;
@property (nonatomic) CGFloat videoPlayerScale;
@property (strong, nonatomic) UIImageView * videoStartMaskView;

@property (strong, nonatomic) GPUImageMovie *movieFile;
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> *filter;
@property (strong, nonatomic) GPUImageMovieWriter *movieWriter;
@property (strong, nonatomic) NSTimer *timerFilter;

@property (strong, nonatomic) AVAssetExportSession *exporter;

@end

@implementation IGCropView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.clipsToBounds = NO;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.alwaysBounceHorizontal = YES;
        self.alwaysBounceVertical = YES;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    _movieFile = nil;
    _filter = nil;
    _movieWriter = nil;
    [_timerFilter invalidate];
    _timerFilter = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // center the zoom view as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.imageView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.imageView.frame = frameToCenter;
    self.videoStartMaskView.hidden = YES;
}


-(UIImageView *)videoStartMaskView
{
    if(!_videoStartMaskView)
    {
        self.videoStartMaskView =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"InstagramAssetsPicker.bundle/Start"] ];
        //FIXME: should use constraint
        self.videoStartMaskView.frame = CGRectMake(self.superview.frame.size.width / 2 + self.superview.frame.origin.x - 25, self.superview.frame.size.height / 2 + self.superview.frame.origin.y - 25, 50, 50);
        [self.superview addSubview:self.videoStartMaskView];
        self.videoStartMaskView.hidden = YES;
    }
    return _videoStartMaskView;
}

- (CGRect)getCropRegion
{
    if(self.alAsset)
    {
        if([_type isEqualToString:ALAssetTypePhoto])
        {
            CGRect visibleRect = [self _calcVisibleRectForCropArea];//caculate visible rect for crop
            CGAffineTransform rectTransform = [self _orientationTransformedRectOfImage:self.imageView.image];//if need rotate caculate
            visibleRect = CGRectApplyAffineTransform(visibleRect, rectTransform);
            
            //convert to 0-1
            CGAffineTransform t;
            if((self.imageView.image.imageOrientation == UIImageOrientationLeft) || ((self.imageView.image.imageOrientation == UIImageOrientationRight)))
                t = CGAffineTransformMakeScale(1.0f / self.imageView.image.size.height, 1.0f / self.imageView.image.size.width);
            else
                t = CGAffineTransformMakeScale(1.0f / self.imageView.image.size.width, 1.0f / self.imageView.image.size.height);
            
            CGRect unitRect = CGRectApplyAffineTransform(visibleRect, t);
            
            //incase <0 or >1
            
            unitRect = [self rangeRestrictForRect:unitRect];
            
            return unitRect;
        }
        else if([_type isEqualToString:ALAssetTypeVideo])
        {
            UIInterfaceOrientation orientation = [IGCropView orientationForTrack:[AVAsset assetWithURL:self.alAsset.defaultRepresentation.url]];
            
            
            CGRect visibleRect = [self convertRect:self.bounds toView:self.videoPlayer.view];
            
            CGAffineTransform t = CGAffineTransformMakeScale(1 / self.videoPlayerScale, 1 / self.videoPlayerScale);
            
            visibleRect = CGRectApplyAffineTransform(visibleRect, t);
            
            //竖屏的视频裁剪框要先转换为横屏模式
            CGFloat y;
            switch (orientation)
            {
                case UIInterfaceOrientationLandscapeLeft:
                    
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    y =  visibleRect.origin.y;
                    visibleRect.origin.y = visibleRect.origin.x;
                    visibleRect.origin.x = y;
                    break;
                default:
                    y =  visibleRect.origin.y;
                    visibleRect.origin.y = visibleRect.origin.x;
                    visibleRect.origin.x = y;
            };
            
            //得到videoTrack正常播放时候进行转换的transform
//            AVAssetTrack *videoTrack = [[[AVAsset assetWithURL:self.alAsset.defaultRepresentation.url] tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//            CGAffineTransform txf = [videoTrack preferredTransform];
            //要剪切的矩形进行坐标转换
//            visibleRect = CGRectApplyAffineTransform(visibleRect, txf);
            
            //转换为0-1 (for GPUImage crop)
//            t = CGAffineTransformMakeScale(1.0f / self.alAsset.defaultRepresentation.dimensions.width, 1.0f / self.alAsset.defaultRepresentation.dimensions.height);
//            
//            CGRect croprect = CGRectApplyAffineTransform(visibleRect, t);
//            croprect = [self rangeRestrictForRect:croprect];
            
            CGRect croprect = visibleRect;
            return croprect;
            
        }
        else
            return CGRectNull;
    }
    else
        return CGRectNull;
}


- (id)cropAsset
{
    return [self cropAlAsset:self.alAsset withRegion:[self getCropRegion]];
}


- (id)cropAlAsset:(ALAsset *)asset withRegion:(CGRect)rect
{
    if(asset)
    {
        if([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto])//photo
        {
            UIImage * image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage scale:asset.defaultRepresentation.scale orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];

            return [self cropImage:image withRegion:rect];
        }
        else if([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo])//video
        {
            AVAsset * avAsset = [self cropVideoByCustom:asset withRegion:rect]; //[self cropVideo:asset withRegion:rect];
            return avAsset;
        }
        else
            return nil;
    }
    else
        return nil;
}


- (CGRect)rangeRestrictForRect:(CGRect )unitRect
{
    // incase <0 or >1
    if(unitRect.origin.x < 0)
        unitRect.origin.x = 0;
    
    if(unitRect.origin.x > 1)
        unitRect.origin.x = 1;
    
    if(unitRect.origin.y < 0)
        unitRect.origin.y = 0;
    
    if(unitRect.origin.y > 1)
        unitRect.origin.y = 1;
    
    if(unitRect.size.height < 0)
        unitRect.size.height = 0;
    
    if(unitRect.size.height > 1)
        unitRect.size.height = 1;
    
    if(unitRect.size.width < 0)
        unitRect.size.width = 0;
    
    if(unitRect.size.width > 1)
        unitRect.size.width = 1;
    
    return unitRect;
}

- (void)stopVideoPlay
{
    if(self.videoPlayer)
    {
        [self.videoPlayer stop];
    }
}

#pragma mark - NSUserDefaults
#pragma mark - ShouldRightRotate90ByCustom
- (void)setShouldRightRotate90ByCustom:(BOOL)shouldRotate withKey:(NSString *)identifier
{
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    if (shouldRotate)
    {
        [userDefaultes setBool:YES forKey:identifier];
    }
    else
    {
        [userDefaultes setBool:NO forKey:identifier];
    }
    
    [userDefaultes synchronize];
}

#pragma mark - Video Process
- (AVAsset *)cropVideoByCustom:(ALAsset *)alAsset withRegion:(CGRect)cropRect
{
    //load our movie Asset
    AVAsset *asset = [AVAsset assetWithURL:alAsset.defaultRepresentation.url];

    //create an avassetrack with our asset
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    //create a video composition and preset some settings
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30);
    //here we are setting its render size to its height x height (Square)
    videoComposition.renderSize = cropRect.size; // CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height);
    
    //create a video instruction
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction
                                                                   videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    

//    UIInterfaceOrientation videoOrientation = orientationForTrack(asset);
//    NSLog(@"videoOrientation: %ld", (long)videoOrientation);
//    if (videoOrientation == UIInterfaceOrientationPortrait)
//    {
//        // Left rotation 90 degree
//        [layerInstruction setCropRectangle:cropRect atTime:kCMTimeZero];
//        
//        CGRect fullRect = CGRectMake(0, 0, clipVideoTrack.naturalSize.width, clipVideoTrack.naturalSize.height);
//        CGAffineTransform t1 = CGAffineTransformMakeTranslation(CGRectGetMidX(fullRect), -CGRectGetMidY(fullRect));
//        CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
//        CGAffineTransform finalTransform = CGAffineTransformConcat(t2, CGAffineTransformMakeTranslation(CGRectGetMidX(cropRect), -CGRectGetMidX(cropRect)));
//        NSLog(@"cropRect: %@", NSStringFromCGRect(cropRect));
//        [layerInstruction setTransform:finalTransform atTime:kCMTimeZero];
//    }
//    else
    {
        [layerInstruction setCropRectangle:cropRect atTime:kCMTimeZero];

        CGAffineTransform t1 = CGAffineTransformMakeTranslation(-1*cropRect.origin.x, -1*cropRect.origin.y);
        [layerInstruction setTransform:t1 atTime:kCMTimeZero];
    }
    
    //add the transformer layer instructions, then add to video composition
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    //Create an Export Path to store the cropped video
    NSString *exportPath = [self getOutputFilePath];
    unlink([exportPath UTF8String]);
    NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
    
    //Export
    _exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
    _exporter.videoComposition = videoComposition;
    _exporter.outputURL = exportUrl;
    _exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Progress monitor for effect
        _timerFilter = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                                        target:self
                                                      selector:@selector(retrievingExportProgress)
                                                      userInfo:nil
                                                       repeats:YES];
    });
    
    __block typeof(self) blockSelf = self;
    [_exporter exportAsynchronouslyWithCompletionHandler:^(void) {
        switch ([_exporter status])
        {
            case AVAssetExportSessionStatusCompleted:
            {
                // Close timer
                [blockSelf.timerFilter invalidate];
                blockSelf.timerFilter = nil;
                
                // Temp solution for video orientation form system camera
                UIInterfaceOrientation videoOrientation = orientationForTrack(asset);
                NSLog(@"videoOrientation: %ld", (long)videoOrientation);
                if (videoOrientation == UIInterfaceOrientationPortrait)
                {
                    NSLog(@"setShouldRightRotate90ByCustom: %@", exportPath);
                    [blockSelf setShouldRightRotate90ByCustom:YES withKey:exportPath];
                }
                else
                {
                    [blockSelf setShouldRightRotate90ByCustom:NO withKey:exportPath];
                }
                
                if (_finishBlock)
                {
                    _finishBlock(YES, [AVAsset assetWithURL:exportUrl]);
                }
                
                NSLog(@"Export Successful: %@", exportPath);
                break;
            }
                
            case AVAssetExportSessionStatusFailed:
            {
                // Close timer
                [blockSelf.timerFilter invalidate];
                blockSelf.timerFilter = nil;
                
                if (_finishBlock)
                {
                    _finishBlock(NO, [AVAsset assetWithURL:exportUrl]);
                }
                
                NSLog(@"Export failed: %@, %@", [[blockSelf.exporter error] localizedDescription], [blockSelf.exporter error]);
                break;
            }
                
            case AVAssetExportSessionStatusCancelled:
            {
                NSLog(@"Canceled: %@", [blockSelf.exporter error]);
                break;
            }
            default:
                break;
        }
    }];
    
    return nil;
}

- (AVAsset *)cropVideo:(ALAsset *)alAsset withRegion:(CGRect)rect
{
    AVAsset *asset = [AVAsset assetWithURL:alAsset.defaultRepresentation.url];

    UIInterfaceOrientation orientation = [IGCropView orientationForTrack:[AVAsset assetWithURL:alAsset.defaultRepresentation.url]];
    
    _movieFile = [[GPUImageMovie alloc] initWithAsset:asset];
    _movieFile.runBenchmark = NO;
    _movieFile.playAtActualSpeed = NO;
    
    _filter = [[GPUImageCropFilter alloc] initWithCropRegion:rect];
    //the camera sensor default orientation is LandscapeLeft
    switch (orientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
            [_filter setInputRotation:kGPUImageNoRotation atIndex:0];
            
            break;
        case UIInterfaceOrientationLandscapeRight:
            [_filter setInputRotation:kGPUImageRotate180 atIndex:0];
            
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            [_filter setInputRotation:kGPUImageRotateLeft atIndex:0];
            
            break;
        default:
            [_filter setInputRotation:kGPUImageRotateRight atIndex:0];
    };
    
    
    [_movieFile addTarget:_filter];
    
    NSString *pathToMovie = [self getOutputFilePath];
    unlink([pathToMovie UTF8String]); // Delete the old movie if existed
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    CGFloat widthVideo = 540;
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(widthVideo, widthVideo)];
    
    [_filter addTarget:_movieWriter];
    
    _movieWriter.shouldPassthroughAudio = YES;
    _movieFile.audioEncodingTarget = _movieWriter;
    [_movieFile enableSynchronizedEncodingUsingMovieWriter:_movieWriter];
    
    [_movieWriter startRecording];
    [_movieFile startProcessing];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Progress monitor for effect
        _timerFilter = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                        target:self
                                                      selector:@selector(retrievingProgressFilter)
                                                      userInfo:nil
                                                       repeats:YES];
    });
    
    __weak GPUImageMovieWriter * weakWriter = _movieWriter;
    __weak GPUImageOutput<GPUImageInput>  * weakFilter = _filter;
    //FIXME:
    __block BOOL finished = NO;
    [weakWriter setCompletionBlock:^{
        
        NSLog(@"Completed Successfully");
        
        [weakWriter finishRecordingWithCompletionHandler:^{
            
            // Closer timer
            [_timerFilter invalidate];
            _timerFilter = nil;
            
            finished = YES;
            
            if (_finishBlock)
            {
                _finishBlock(YES, [AVAsset assetWithURL:movieURL]);
            }
        }];
        
        [weakFilter removeTarget:weakWriter];
        
    }];
//    while (!finished);
    
    return [AVAsset assetWithURL:movieURL];
}

#pragma mark - getOutputFilePath
- (NSString*)getOutputFilePath
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];

    NSString *fileName = [[NSTemporaryDirectory() stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mov"];
    return fileName;
}

#pragma mark - retrievingProgressFilter
- (void)retrievingProgressFilter
{
    if (_movieFile.progress >= 0 && _exportProgressBlock)
    {
        CGFloat progress = _movieFile.progress;
        NSLog(@"ProgressFilter: %@", [NSString stringWithFormat:@"%d%%", (int)(progress * 100)]);
        
        self.exportProgressBlock([NSNumber numberWithFloat:progress]);
    }
}

- (void)retrievingExportProgress
{
    if (_exporter && _exportProgressBlock)
    {
        self.exportProgressBlock([NSNumber numberWithFloat:_exporter.progress]);
    }
}

#pragma mark -Image Process

- (UIImage *)cropImage:(UIImage *)image withRegion:(CGRect)rect
{
    GPUImagePicture * picture = [[GPUImagePicture alloc] initWithImage:image];
    
    GPUImageCropFilter * cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:rect];
    
    [picture addTarget:cropFilter];
    [cropFilter useNextFrameForImageCapture];
    [picture processImage];
    
    UIImage * returnImage =[cropFilter imageFromCurrentFramebufferWithOrientation:image.imageOrientation];
    
    if (_finishBlock)
    {
        _finishBlock(YES, returnImage);
    }
    
    return returnImage;
}


static CGRect IGScaleRect(CGRect rect, CGFloat scale)
{
    return CGRectMake(rect.origin.x * scale, rect.origin.y * scale, rect.size.width * scale, rect.size.height * scale);
}

-(CGRect)_calcVisibleRectForCropArea
{
    
    CGFloat sizeScale = self.imageView.image.size.width / self.imageView.frame.size.width;
    sizeScale *= self.zoomScale;
    CGRect visibleRect = [self convertRect:self.bounds toView:self.imageView];
    return visibleRect = IGScaleRect(visibleRect, sizeScale);
}

- (CGAffineTransform)_orientationTransformedRectOfImage:(UIImage *)img
{
    CGAffineTransform rectTransform;
    switch (img.imageOrientation)
    {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -img.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -img.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -img.size.width, -img.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    
    return CGAffineTransformScale(rectTransform, img.scale, img.scale);
}


+ (UIInterfaceOrientation)orientationForTrack:(AVAsset *)asset
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];
    
    if (size.width == txf.tx && size.height == txf.ty)
        return UIInterfaceOrientationLandscapeRight;
    else if (txf.tx == 0 && txf.ty == 0)
        return UIInterfaceOrientationLandscapeLeft;
    else if (txf.tx == 0 && txf.ty == size.width)
        return UIInterfaceOrientationPortraitUpsideDown;
    else
        return UIInterfaceOrientationPortrait;
}


- (void)setAlAsset:(ALAsset *)asset
{
    _alAsset = asset;
    _type   = [asset valueForProperty:ALAssetPropertyType];
    
    // clear the previous image
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    if(self.videoPlayer)
    {
        [self.videoPlayer stop];
        [self.videoPlayer.view removeFromSuperview];
    }

    //hide start mask and add observer
    self.videoStartMaskView.hidden = YES;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    
    if([_type isEqual:ALAssetTypePhoto])//photo
    {
        UIImage * image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage scale:asset.defaultRepresentation.scale orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];
        // reset our zoomScale to 1.0 before doing any further calculations
        self.zoomScale = 1.0;
        
        // make a new UIImageView for the new image
        self.imageView = [[UIImageView alloc] initWithImage:image];
        self.imageView.clipsToBounds = NO;
        [self addSubview:self.imageView];
        
        
        CGRect frame = self.imageView.frame;
        if (image.size.height > image.size.width)
        {
            frame.size.width = self.bounds.size.width;
            frame.size.height = (self.bounds.size.width / image.size.width) * image.size.height;
        }
        else
        {
            frame.size.height = self.bounds.size.height;
            frame.size.width = (self.bounds.size.height / image.size.height) * image.size.width;
        }
        self.imageView.frame = frame;
        [self configureForImageSize:self.imageView.bounds.size];
        _playState = 0;
    }
    else
    {
        self.videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:asset.defaultRepresentation.url];
        self.videoPlayer.controlStyle = MPMovieControlStyleNone;
        self.videoPlayer.movieSourceType = MPMovieSourceTypeFile;
        self.videoPlayer.scalingMode = MPMovieScalingModeAspectFill;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishedCallBack:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        
        CGSize assetSize = asset.defaultRepresentation.dimensions;
        CGSize size;
        if (assetSize.height > assetSize.width)
        {
            size.width = self.bounds.size.width;
            size.height = (self.bounds.size.width / assetSize.width) * assetSize.height;
            self.videoPlayerScale =  self.bounds.size.width / assetSize.width;
        }
        else
        {
            size.height = self.bounds.size.height;
            size.width = (self.bounds.size.height / assetSize.height) * assetSize.width;
            self.videoPlayerScale =  self.bounds.size.height / assetSize.height;
        }
        
        self.videoPlayer.view.frame = CGRectMake(0, 0, size.width, size.height);

        [self addSubview:self.videoPlayer.view];
        [self.videoPlayer play];
        [self configureForImageSize:self.videoPlayer.view.frame.size];
        
        _playState = 1;
    }
}

- (void)configureForImageSize:(CGSize)imageSize
{
    _imageSize = imageSize;
    self.contentSize = imageSize;
    
    //to center
    if (imageSize.width > imageSize.height)
    {
        self.contentOffset = CGPointMake(imageSize.width/4, 0);
    }
    else if (imageSize.width < imageSize.height)
    {
        self.contentOffset = CGPointMake(0, imageSize.height/4);
    }
    
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    self.minimumZoomScale = 1.0;
    self.maximumZoomScale = 2.0;
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if((self.videoPlayer) && (_playState == 2))
    {
        _playState = 1;
        [self.videoPlayer play];
        self.videoStartMaskView.hidden = YES;
    }
}

#pragma mark - MPMoviePlayerController Notification
- (void) playerDidFinishedCallBack:(NSNotification *)notification
{
    _playState = 2;
    self.videoStartMaskView.hidden = NO;
}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

@end
