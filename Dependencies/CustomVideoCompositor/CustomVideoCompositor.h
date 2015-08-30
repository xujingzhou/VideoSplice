//
//  CustomVideoCompositor
//  PicInPic
//
//  Created by Johnny Xu(徐景周) on 5/19/15.
//  Copyright (c) 2015 Johnny Xu. All rights reserved.
//
#import <Foundation/Foundation.h>
@import AVFoundation;

typedef NS_ENUM(NSInteger, MirrorType)
{
    kMirrorNone = 0,
    kMirrorLeftRightMirror,
    kMirrorUpDownReflection,
    kMirror4Square,
};

@interface CustomVideoCompositor : NSObject<AVVideoCompositing>

@end
