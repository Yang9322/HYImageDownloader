//
//  HYImageDownloader.h
//  HYImageDownloader
//
//  Created by He yang on 16/5/2.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYImageDownloader.h"
#import "HYImageCache.h"
#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,HYImageDownloadPrioritization){
    HYImageDownloadFIFO,
    HYImageDownloadFILO
};


@interface HYImageDownloadReceipt : NSObject

@property (nonatomic,strong)NSURLSessionTask *task;

@property (nonatomic,strong)NSUUID *receipitID;

@end

@interface HYImageDownloader : NSObject

@property (nonatomic,strong)NSURLSession *session;

@property (nonatomic,assign)HYImageDownloadPrioritization downloadPrioritization;

@property (nonatomic,assign)NSInteger maxDownloadCount;

@property (nonatomic,strong)id <HYImageCache> imageCache;



+ (instancetype)shareInstance;

- (HYImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)URLRequest
                     withReceiptID:(NSUUID *)receiptID
                           success:(void (^) (NSURLRequest *request ,NSHTTPURLResponse *response,UIImage *responseObject))succss
                           failure:( void (^)(NSURLRequest *request, NSHTTPURLResponse * response, NSError *error))failure;


- (void)cancelTaskWithURLRequest:(NSURLRequest *)URLRequest;




@end
