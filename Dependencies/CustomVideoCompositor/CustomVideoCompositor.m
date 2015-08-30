//
//  CustomVideoCompositor
//  PicInPic
//
//  Created by Johnny Xu(徐景周) on 5/19/15.
//  Copyright (c) 2015 Johnny Xu. All rights reserved.
//
@import  UIKit;
#import "CustomVideoCompositor.h"
#import "GPUImageWaveFilter.h"

@interface CustomVideoCompositor()

@property (nonatomic, strong) GPUImageWaveFilter *waveFilter;

@end

@implementation CustomVideoCompositor

- (instancetype)init
{
    return self;
}

#pragma mark - startVideoCompositionRequest
- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request
{
    NSMutableArray *videoArray = [[NSMutableArray alloc] init];
    CVPixelBufferRef destination = [request.renderContext newPixelBuffer];
    if (request.sourceTrackIDs.count > 0)
    {
        for (NSUInteger i = 0; i < [request.sourceTrackIDs count]; ++i)
        {
            CVPixelBufferRef videoBufferRef = [request sourceFrameByTrackID:[[request.sourceTrackIDs objectAtIndex:i] intValue]];
            if (videoBufferRef)
            {
                [videoArray addObject:(__bridge id)(videoBufferRef)];
            }
        }
        
        for (NSUInteger i = 0; i < [videoArray count]; ++i)
        {
            CVPixelBufferRef video = (__bridge CVPixelBufferRef)([videoArray objectAtIndex:i]);
            CVPixelBufferLockBaseAddress(video, kCVPixelBufferLock_ReadOnly);
        }
        CVPixelBufferLockBaseAddress(destination, 0);
        
        [self renderBuffer:videoArray toBuffer:destination];
        
        CVPixelBufferUnlockBaseAddress(destination, 0);
        for (NSUInteger i = 0; i < [videoArray count]; ++i)
        {
            CVPixelBufferRef video = (__bridge CVPixelBufferRef)([videoArray objectAtIndex:i]);
            CVPixelBufferUnlockBaseAddress(video, kCVPixelBufferLock_ReadOnly);
        }
    }
    
    [request finishWithComposedVideoFrame:destination];
    CVBufferRelease(destination);
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext
{
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext
{
    return @{ (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @[ @(kCVPixelFormatType_32BGRA) ] };
}

- (NSDictionary *)sourcePixelBufferAttributes
{
    return @{ (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @[ @(kCVPixelFormatType_32BGRA) ] };
}

#pragma mark - renderBuffer
- (void)renderBuffer:(NSMutableArray *)videoBufferRefArray toBuffer:(CVPixelBufferRef)destination
{
    size_t width = CVPixelBufferGetWidth(destination);
    size_t height = CVPixelBufferGetHeight(destination);
    NSMutableArray *imageRefArray = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < [videoBufferRefArray count]; ++i)
    {
        CVPixelBufferRef videoFrame = (__bridge CVPixelBufferRef)([videoBufferRefArray objectAtIndex:i]);
        CGImageRef imageRef = [self createSourceImageFromBuffer:videoFrame];
        if (imageRef)
        {
            if ([self shouldRightRotate90ByTrackID:i+1])
            {
                // Right rotation 90
                imageRef = CGImageRotated(imageRef, degreesToRadians(90));
            }
            
            [imageRefArray addObject:(__bridge id)(imageRef)];
        }
        CGImageRelease(imageRef);
    }
    
    if ([imageRefArray count] < 1)
    {
        NSLog(@"imageRefArray is empty.");
        return;
    }
    
    CGContextRef gc = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(destination), width, height, 8, CVPixelBufferGetBytesPerRow(destination), CGImageGetColorSpace((CGImageRef)imageRefArray[0]), CGImageGetBitmapInfo((CGImageRef)imageRefArray[0]));
    
    CGRect fullFrame = CGRectMake(0, 0, width, height);
    MirrorType type = [self getMirrorType];
    if (type == kMirrorLeftRightMirror)
    {
        // Left/Right
        CGRect leftMirrorFrame = CGRectMake(0, 0, width/2, height);
        CGRect rightFrame = CGRectMake(width/2, 0, width/2, height);
        NSArray *arrayRect = [NSArray arrayWithObjects:[NSValue valueWithCGRect:fullFrame], [NSValue valueWithCGRect:leftMirrorFrame], [NSValue valueWithCGRect:rightFrame], nil];
        [self drawBorderInFrames:arrayRect withContextRef:gc];
        CGContextDrawImage(gc, rightFrame, (CGImageRef)imageRefArray[0]);
        
        if (!CGRectIsEmpty(leftMirrorFrame))
        {
            // Horizontal Mirror
            CGContextTranslateCTM(gc, width/2, 0);
            CGContextScaleCTM(gc, -1.0, 1.0);
            
            CGImageRef waveImage = (__bridge CGImageRef)(imageRefArray[0]);
            if ([self shouldDisplayWaveMirrorEffect])
            {
                waveImage = [self getWaveFilterImage:(__bridge CGImageRef)(imageRefArray[0]) withMirrorType:kMirrorLeftRightMirror];
                CGContextDrawImage(gc, leftMirrorFrame, waveImage);
                CGImageRelease(waveImage);
            }
            else
            {
                CGContextDrawImage(gc, leftMirrorFrame, waveImage);
            }
        }
    }
    else if (type == kMirrorUpDownReflection)
    {
        // Up/Down
        CGRect upFrame = CGRectMake(0, 0, width, height/2);
        CGRect downReflectionFrame = CGRectMake(0, height/2, width, height/2);
        NSArray *arrayRect = [NSArray arrayWithObjects:[NSValue valueWithCGRect:fullFrame], [NSValue valueWithCGRect:upFrame], [NSValue valueWithCGRect:downReflectionFrame], nil];
        [self drawBorderInFrames:arrayRect withContextRef:gc];
        CGContextDrawImage(gc, downReflectionFrame, (CGImageRef)imageRefArray[0]);
        
//        CGImageRef gradientMaskImage = createGradientImage(height/2, height/2, 0.1, 0.8);
//        // Gradient Mask
//        CGContextClipToMask(gc, upFrame, gradientMaskImage);
//        CGImageRelease(gradientMaskImage);
        
        // Vertical Mirror
        CGContextTranslateCTM(gc, 0.0, upFrame.size.height);
        CGContextScaleCTM(gc, 1.0, -1.0);
        
        CGImageRef waveImage = (__bridge CGImageRef)(imageRefArray[0]);
        if ([self shouldDisplayWaveMirrorEffect])
        {
            waveImage = [self getWaveFilterImage:(__bridge CGImageRef)(imageRefArray[0]) withMirrorType:kMirrorUpDownReflection];
            CGContextDrawImage(gc, upFrame, waveImage);
            CGImageRelease(waveImage);
        }
        else
        {
            CGContextDrawImage(gc, upFrame, waveImage);
        }
    }
    else if (type == kMirror4Square)
    {
        if ([imageRefArray count] != 4)
        {
            NSLog(@"k4Square video count != 4.");
            CGContextRelease(gc);
            return;
        }
        
        // 4 Square
        CGRect leftTopFrame = CGRectMake(0, 0, width/2, height/2);
        CGRect rightTopFrame = CGRectMake(width/2, 0, width/2, height/2);
        CGRect leftBottomFrame = CGRectMake(0, height/2, width/2, height/2);
        CGRect rightBottomFrame = CGRectMake(width/2, height/2, width/2, height/2);
        NSArray *arrayRect = [NSArray arrayWithObjects:[NSValue valueWithCGRect:fullFrame], [NSValue valueWithCGRect:leftTopFrame], [NSValue valueWithCGRect:rightTopFrame], [NSValue valueWithCGRect:leftBottomFrame], [NSValue valueWithCGRect:rightBottomFrame], nil];
        [self drawBorderInFrames:arrayRect withContextRef:gc];
        
        CGContextDrawImage(gc, leftTopFrame, (CGImageRef)imageRefArray[0]);
        CGContextDrawImage(gc, rightTopFrame, (CGImageRef)imageRefArray[1]);
        CGContextDrawImage(gc, leftBottomFrame, (CGImageRef)imageRefArray[2]);
        CGContextDrawImage(gc, rightBottomFrame, (CGImageRef)imageRefArray[3]);
    }
    else
    {
        NSLog(@"getMirrorType is empty.");
    }
    
    CGContextRelease(gc);
}

#pragma mark - createSourceImageFromBuffer
- (CGImageRef)createSourceImageFromBuffer:(CVPixelBufferRef)buffer
{
    size_t width = CVPixelBufferGetWidth(buffer);
    size_t height = CVPixelBufferGetHeight(buffer);
    size_t stride = CVPixelBufferGetBytesPerRow(buffer);
    void *data = CVPixelBufferGetBaseAddress(buffer);
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, height * stride, NULL);
    CGImageRef image = CGImageCreate(width, height, 8, 32, stride, rgb, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast, provider, NULL, NO, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgb);
    
    return image;
}

#pragma mark - CGImageRotated
CGImageRef CGImageRotated(CGImageRef originalCGImage, double radians)
{
    CGSize imageSize = CGSizeMake(CGImageGetWidth(originalCGImage), CGImageGetHeight(originalCGImage));
    CGSize rotatedSize;
    if (radians == M_PI_2 || radians == -M_PI_2)
    {
        rotatedSize = CGSizeMake(imageSize.height, imageSize.width);
    }
    else
    {
        rotatedSize = imageSize;
    }
    
    double rotatedCenterX = rotatedSize.width / 2.f;
    double rotatedCenterY = rotatedSize.height / 2.f;
    
//    //bitmap context properties
//    CGSize size = imageSize;
//    NSUInteger bytesPerPixel = 4;
//    NSUInteger bytesPerRow = bytesPerPixel * size.width;
//    NSUInteger bitsPerComponent = 8;
//    
//    //create bitmap context
//    unsigned char *rawData = malloc(size.height * size.width * 4);
//    memset(rawData, 0, size.height * size.width * 4);
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    CGContextRef rotatedContext = CGBitmapContextCreate(rawData, size.width, size.height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    
    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, 1.f);
    CGContextRef rotatedContext = UIGraphicsGetCurrentContext();
    if (radians == 0.f || radians == M_PI)
    {
        // 0 or 180 degrees
        CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
        if (radians == 0.0f)
        {
            CGContextScaleCTM(rotatedContext, 1.f, -1.f);
        }
        else
        {
            CGContextScaleCTM(rotatedContext, -1.f, 1.f);
        }
        CGContextTranslateCTM(rotatedContext, -rotatedCenterX, -rotatedCenterY);
    }
    else if (radians == M_PI_2 || radians == -M_PI_2)
    {
        // +/- 90 degrees
        CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
        CGContextRotateCTM(rotatedContext, radians);
        CGContextScaleCTM(rotatedContext, 1.f, -1.f);
        CGContextTranslateCTM(rotatedContext, -rotatedCenterY, -rotatedCenterX);
    }
    
    CGRect drawingRect = CGRectMake(0.f, 0.f, imageSize.width, imageSize.height);
    CGContextDrawImage(rotatedContext, drawingRect, originalCGImage);
    CGImageRef rotatedCGImage = CGBitmapContextCreateImage(rotatedContext);
    
    UIGraphicsEndImageContext();
    
//    CGColorSpaceRelease(colorSpace);
//    CGContextRelease(rotatedContext);
//    free(rawData);
    
    return rotatedCGImage;
}

#pragma mark - drawBorderInFrame
- (void)drawBorderInFrames:(NSArray *)frames withContextRef:(CGContextRef)contextRef
{
    if (!frames || [frames count] < 1)
    {
        NSLog(@"drawBorderInFrames is empty.");
        return;
    }
    
    if ([self shouldDisplayInnerBorder])
    {
        // Fill background
        CGContextSetFillColorWithColor(contextRef, [UIColor whiteColor].CGColor);
        CGContextFillRect(contextRef, [frames[0] CGRectValue]);
        
        // Draw
        CGContextBeginPath(contextRef);
        CGFloat lineWidth = 5;
        for (int i = 1; i < [frames count]; ++i)
        {
            CGRect innerVideoRect = [frames[i] CGRectValue];
            if (!CGRectIsEmpty(innerVideoRect))
            {
                CGContextAddRect(contextRef, CGRectInset(innerVideoRect, lineWidth, lineWidth));
            }
        }
        CGContextClip(contextRef);
    }
}

#pragma mark - getWaveFilterImage
static CGFloat factor = 0;
- (CGImageRef)getWaveFilterImage:(CGImageRef)originImage withMirrorType:(MirrorType)mirrorType
{
    CGFloat sign = 1, step = 0.8, maxLen = 1000, minLen = 0;
    CGImageRef result = nil;
    if (originImage)
    {
        if (factor >= maxLen)
        {
            factor = maxLen;
            sign = -1;
        }
        else if (factor <= minLen)
        {
            factor = minLen;
            sign = 1;
        }
        
        factor = factor + sign*step;
        if (!_waveFilter)
        {
            _waveFilter = [[GPUImageWaveFilter alloc] init];
        }
        
        _waveFilter.normalizedPhase = factor;
        if (mirrorType == kMirrorLeftRightMirror)
        {
            _waveFilter.centerX = -0.1;
            _waveFilter.centerY = 0.5;
        }
        else if (mirrorType == kMirrorUpDownReflection)
        {
            _waveFilter.centerX = 0.5;
            _waveFilter.centerY = 1.1;
        }
        result = [_waveFilter newCGImageByFilteringCGImage:originImage];
    }
   
    return result;
}

#pragma mark - NSUserDefaults
// Test
- (NSArray *)getFrames
{
    NSArray *arrayResult = nil;
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    NSData *dataRect = [userDefaultes objectForKey:@"arrayRect"];
    if (dataRect)
    {
        arrayResult = [NSKeyedUnarchiver unarchiveObjectWithData:dataRect];
        if (arrayResult && [arrayResult count] > 0)
        {
            CGRect innerVideoRect = [arrayResult[0] CGRectValue];
            if (!CGRectIsEmpty(innerVideoRect))
            {
                NSLog(@"[arrayResult[0] CGRectValue: %@", NSStringFromCGRect(innerVideoRect));
            }
        }
    }
    
    return arrayResult;
}

#pragma mark - ShouldDisplayWaveMirrorEffect
- (BOOL)shouldDisplayWaveMirrorEffect
{
    NSString *shouldDisplayWaveMirrorEffect = @"ShouldDisplayWaveMirrorEffect";
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    BOOL shouldDisplay = [[userDefaultes objectForKey:shouldDisplayWaveMirrorEffect] boolValue];
//    NSLog(@"ShouldDisplayWaveMirrorEffect: %@", shouldDisplay?@"Yes":@"No");
    
    if (shouldDisplay)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - getMirrorType
- (MirrorType)getMirrorType
{
    MirrorType type = kMirrorNone;
    NSString *mirrorType = @"MirrorType";
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    if ([userDefaultes integerForKey:mirrorType])
    {
        type = [userDefaultes integerForKey:mirrorType];
//        NSLog(@"getMirrorType: %lu", type);
    }
    
    return type;
}

#pragma mark - shouldDisplayInnerBorder
- (BOOL)shouldDisplayInnerBorder
{
    NSString *shouldDisplayInnerBorder = @"ShouldDisplayInnerBorder";
//    NSLog(@"shouldDisplayInnerBorder: %@", [[[NSUserDefaults standardUserDefaults] objectForKey:shouldDisplayInnerBorder] boolValue]?@"Yes":@"No");
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:shouldDisplayInnerBorder] boolValue])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - shouldRightRotate90ByTrackID
- (BOOL)shouldRightRotate90ByTrackID:(NSInteger)trackID
{
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    NSString *identifier = [NSString stringWithFormat:@"TrackID_%ld", (long)trackID];
    BOOL result = [[userDefaultes objectForKey:identifier] boolValue];
    NSLog(@"shouldRightRotate90ByTrackID %@ : %@", identifier, result?@"Yes":@"No");
    
    if (result)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
