//
//  IGAssetsPickerViewController.h
//  InstagramAssetsPicker
//
//  Created by JG on 2/3/15.
//  Copyright (c) 2015 JG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, MediaType)
{
    OnlyPhotos = 0,
    OnlyVideos,
    ALlMedia
};

@protocol IGAssetsPickerDelegate <NSObject>

//get crop region , range:0-1, you can crop when user post for good UE
-(void)IGAssetsPickerGetCropRegion:(CGRect)rect withAlAsset:(ALAsset *)asset;

//crop immediatly
-(void)IGAssetsPickerFinishCroppingToAsset:(id)asset;

@end

@interface IGAssetsPickerViewController : UIViewController

@property (nonatomic, strong) id<IGAssetsPickerDelegate> delegate;

@property (nonatomic, assign) MediaType mediaType;
@property (nonatomic, assign) CGFloat videoMaxLength;

@end

