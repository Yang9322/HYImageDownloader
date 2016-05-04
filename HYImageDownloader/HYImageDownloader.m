//
//  HYImageDownloader.m
//  HYImageDownloader
//
//  Created by He yang on 16/5/2.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "HYImageDownloader.h"

@interface HYImageDownloader ()

@property (nonatomic,strong)dispatch_queue_t synchronizationQueue;

@property (nonatomic,strong)dispatch_queue_t responseQueue;

@property (nonatomic,strong)NSMutableArray *queuedTasks;

@property (nonatomic,strong)NSMutableDictionary *mergedTasks;

@property (nonatomic,assign)NSInteger activeTaskCount;

@end

@interface HYImageResponseHandler : NSObject

@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, copy) void (^successBlock)(NSURLRequest*, NSHTTPURLResponse*, UIImage*);
@property (nonatomic, copy) void (^failureBlock)(NSURLRequest*, NSHTTPURLResponse*, NSError*);

@end

@interface HYImageDownloadMergedTask :NSObject

@property (nonatomic,strong)NSString *URLIdentifier;

@property (nonatomic,strong)NSUUID *UUIDItendifier;

@property (nonatomic,strong)NSURLSessionDataTask *task;

@property (nonatomic,strong)HYImageResponseHandler *responseHandler;

@end

@implementation HYImageDownloadReceipt


- (instancetype)initWithReceipt:(NSUUID *)receiptID sessionTask:(NSURLSessionDataTask *)task {

    if (self = [super init]) {
        _receipitID = receiptID;
        _task = task;
    }
    return self;
}

@end


@implementation HYImageResponseHandler

- (instancetype)initWithUUID:(NSUUID *)uuid
                     success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *responseObject))success
                     failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure {
    if (self = [self init]) {
        self.uuid = uuid;
        self.successBlock = success;
        self.failureBlock = failure;
    }
    return self;
}

@end

@implementation HYImageDownloadMergedTask

- (instancetype)initWithURLIdentifier:(NSString *)URLIdentifier UIIDIdentifier:(NSUUID *)UUID task:(NSURLSessionDataTask *)task responseHandlers:(HYImageResponseHandler *)responseHandler{
    if (self = [super init]) {
        _URLIdentifier = URLIdentifier;
        _UUIDItendifier = UUID;
        _task = task;
        _responseHandler = responseHandler;
    }
    return self;
}



@end


@implementation HYImageDownloader

+ (instancetype)shareInstance{
    static HYImageDownloader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init{
    NSURLSessionConfiguration *defaultConfiguration = [NSURLSessionConfiguration  defaultSessionConfiguration];
//   HTTPShouldSetCookies defult is YES
//    defaultConfiguration.HTTPShouldSetCookies = YES;
    defaultConfiguration.HTTPShouldUsePipelining = NO;
    defaultConfiguration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    defaultConfiguration.allowsCellularAccess = YES;
    defaultConfiguration.timeoutIntervalForRequest = 60.0;
    defaultConfiguration.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:20 * 1024 * 1024 diskCapacity:100 * 1024 * 1024 diskPath:@"com.heyang.imageDownloader"];
    NSURLSession *session = [NSURLSession  sessionWithConfiguration:defaultConfiguration];

    
    return [self initWithSession:session
                 downloadPrioritization:HYImageDownloadFIFO
                 maxActiveDownloadsCount:4
                             imageCache:[[HYImageCache alloc] init]];

    
}


- (instancetype)initWithSession: (NSURLSession *)session
         downloadPrioritization:(HYImageDownloadPrioritization)downloadPrioritization maxActiveDownloadsCount: (NSInteger)maxCounts
                      imageCache:(id <HYImageCache>)imageCache{
    if (self = [super init]) {
        self.session = session;
        self.downloadPrioritization = downloadPrioritization;
        self.maxDownloadCount = maxCounts;
        self.imageCache = imageCache;
        self.queuedTasks = [NSMutableArray array];
        self.mergedTasks = [NSMutableDictionary dictionary];
        self.activeTaskCount = 0;
        NSString *name = [NSString stringWithFormat:@"com.heyang.imagedownloader.synchronizationqueue-%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        name = [NSString stringWithFormat:@"com.heyang.imagedownloader.responsequeue-%@", [[NSUUID UUID] UUIDString]];
        self.responseQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);


        
    }
    return self;
}


-(HYImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)URLRequest withReceiptID:(NSUUID *)receiptID success:(void (^)(NSURLRequest *, NSHTTPURLResponse *, UIImage *))succss failure:(void (^)(NSURLRequest *, NSHTTPURLResponse *, NSError *))failure{
    
    __block NSURLSessionDataTask *task = nil;
    
    dispatch_sync(self.synchronizationQueue, ^{
        NSString *URLIdentifier = URLRequest.URL.absoluteString;
        if (!URLIdentifier) {
            if (failure) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(URLRequest,nil,error);
                });
            }
            return ;
        }
        
        HYImageDownloadMergedTask *exsitingMergedTask = self.mergedTasks[URLIdentifier];
        if (exsitingMergedTask) {
            
            task = exsitingMergedTask.task;
            return;
        }
        
        switch (URLRequest.cachePolicy) {
            case NSURLRequestUseProtocolCachePolicy:
            case NSURLRequestReturnCacheDataElseLoad:
            case NSURLRequestReturnCacheDataDontLoad:{
                //尝试从缓存中取图片并调用success
                
                
                
            }
                break;
                
            default:
                break;
        }
        
       NSURLSessionDataTask *createdTask = [self.session dataTaskWithRequest:URLRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
           HYImageDownloadMergedTask *mergeTask = self.mergedTasks[URLIdentifier];
           if (mergeTask) {
               
               [self removeMergedTaskWithURLIdentifier:URLRequest.URL.absoluteString];
               if (error) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                       mergeTask.responseHandler.failureBlock(URLRequest,nil,error);
                   });
               }else{
                   UIImage *image = [UIImage imageWithData:data];
                   dispatch_async(dispatch_get_main_queue(), ^{
                       mergeTask.responseHandler.successBlock(URLRequest,(NSHTTPURLResponse *)response,image);
                   });
                   
               }
           }
          
            
        }];
        
        HYImageResponseHandler *handler = [[HYImageResponseHandler alloc] initWithUUID:receiptID success:succss failure:failure];
        
        HYImageDownloadMergedTask *mergedTask = [[HYImageDownloadMergedTask alloc]initWithURLIdentifier:URLRequest.URL.absoluteString UIIDIdentifier:receiptID task:createdTask responseHandlers:handler];
        
        self.mergedTasks[URLIdentifier] = mergedTask;
        
      
        task = mergedTask.task;
    
    });
    
    if (task) {
        HYImageDownloadReceipt *receipt = [[HYImageDownloadReceipt alloc] initWithReceipt:receiptID sessionTask:task];
        [task resume];

        return receipt;
    }else{
        return nil;
    }
    
    
}

- (void)removeMergedTaskWithURLIdentifier:(NSString *)URLIdentifier{
    dispatch_async(self.synchronizationQueue, ^{
        [self.mergedTasks removeObjectForKey:URLIdentifier];

    });
}



@end
