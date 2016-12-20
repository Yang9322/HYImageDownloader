//
//  HYImageDownloader.h
//  HYImageDownloader
//
//  Created by He yang on 16/5/2.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYImageDownloader.h"
#import "HYCacheManager.h"
#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,HYImageDownloadPrioritization){
    HYImageDownloadFIFO,
    HYImageDownloadFILO
};


typedef NS_OPTIONS(NSInteger,HYImageDowloaderOptions) {
    HYImageDowloaderOptionNone = 1 << 0,//Default no options
    HYImageDowloaderOptionFadeAnimation = 1 << 1,//When download image successfully,add a fade animation to image
    HYImageDowloaderOptionRoundedRect = 1 << 2, //When download image successfully,clip the imageView with cornerRadius
    HYImageDowloaderOptionsIgnoreCache = 1 << 3  // Download image directly,igonore the memory cache and disk cache
    //To be continued ...
};

@interface HYImageDownloadReceipt : NSObject

@property (nonatomic,strong)NSURLSessionTask *task;

@property (nonatomic,strong)NSUUID *receipitID;

@end

@interface HYImageDownloader : NSObject

@property (nonatomic,strong)NSURLSession *session;

@property (nonatomic,assign)HYImageDownloadPrioritization downloadPrioritization;

@property (nonatomic,assign)NSInteger maxDownloadCount;

@property (nonatomic,strong)HYCacheManager *imageCache;


+ (instancetype)shareInstance;

- (HYImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)URLRequest
                                         withReceiptID:(NSUUID *)receiptID
                                               success:(void (^) (NSURLRequest *request ,NSHTTPURLResponse *response,UIImage *responseObject))succss
                                               failure:( void (^)(NSURLRequest *request, NSHTTPURLResponse * response, NSError *error))failure
                                               options:(HYImageDowloaderOptions) options;


- (void)cancelTaskWithURLRequest:(NSURLRequest *)URLRequest;

- (void)cancelTaskWithReceipt:(HYImageDownloadReceipt *)receipt;


@end
