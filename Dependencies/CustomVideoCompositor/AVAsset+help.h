//
//  AVAsset (help)
//  PicInPic
//
//  Created by Johnny Xu(徐景周) on 5/19/15.
//  Copyright (c) 2015 Johnny Xu. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>

@interface AVAsset (help)

+ (instancetype)assetWithResourceName:(NSString *)name;
+ (instancetype)assetWithFileURL:(NSURL *)url;
- (AVAssetTrack *)firstVideoTrack;

- (void)whenProperties:(NSArray *)propertyNames areReadyDo:(void (^)(void))block;

@end
