//
//  ExportEffects
//  PicInPic
//
//  Created by Johnny Xu(徐景周) on 5/30/15.
//  Copyright (c) 2015 Future Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CustomVideoCompositor.h"

typedef NSString *(^JZOutputFilenameBlock)();
typedef void (^JZFinishVideoBlock)(BOOL success, id result);
typedef void (^JZExportProgressBlock)(NSNumber *percentage);

@interface ExportEffects : NSObject

@property (copy, nonatomic) JZFinishVideoBlock finishVideoBlock;
@property (copy, nonatomic) JZExportProgressBlock exportProgressBlock;
@property (copy, nonatomic) JZOutputFilenameBlock filenameBlock;

@property (nonatomic) MirrorType mirrorType;

+ (ExportEffects *)sharedInstance;

- (void)addEffectToVideo:(NSArray *)videoFilePathArray withAudioFilePath:(NSString *)audioFilePath;
- (void)writeExportedVideoToAssetsLibrary:(NSString *)outputPath;

@end
