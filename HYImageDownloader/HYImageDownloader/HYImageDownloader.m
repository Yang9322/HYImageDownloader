//
//  HYImageDownloader.m
//  HYImageDownloader
//
//  Created by He yang on 16/5/2.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "HYImageDownloader.h"
#import "UIImage+Decode.h"

@interface HYImageDownloader ()

@property (nonatomic,strong)dispatch_queue_t synchronizationQueue;

@property (nonatomic,strong)dispatch_queue_t responseQueue;

@property (nonatomic,strong)dispatch_queue_t decodeQueue;

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

@property (nonatomic,strong)NSMutableArray *responseHandlers;

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

- (instancetype)initWithURLIdentifier:(NSString *)URLIdentifier UIIDIdentifier:(NSUUID *)UUID task:(NSURLSessionDataTask *)task responseHandlers:(NSMutableArray *)responseHandlers{
    if (self = [super init]) {
        _URLIdentifier = URLIdentifier;
        _UUIDItendifier = UUID;
        _task = task;
        _responseHandlers = responseHandlers;
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
    defaultConfiguration.HTTPShouldUsePipelining = NO;
    defaultConfiguration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    defaultConfiguration.allowsCellularAccess = YES;
    defaultConfiguration.timeoutIntervalForRequest = 60.0;
    defaultConfiguration.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:20 * 1024 * 1024 diskCapacity:100 * 1024 * 1024 diskPath:@"com.heyang.imageDownloader"];
    NSURLSession *session = [NSURLSession  sessionWithConfiguration:defaultConfiguration];

    
    return [self initWithSession:session
                 downloadPrioritization:HYImageDownloadFIFO
                 maxActiveDownloadsCount:16
                             imageCache:[HYCacheManager sharedInstance]];
 
}


- (instancetype)initWithSession: (NSURLSession *)session
         downloadPrioritization:(HYImageDownloadPrioritization)downloadPrioritization maxActiveDownloadsCount: (NSInteger)maxCounts
                      imageCache:(HYCacheManager *)imageCache{
    if (self = [super init]) {
        _session = session;
        _downloadPrioritization = downloadPrioritization;
        _maxDownloadCount = maxCounts;
        _imageCache = imageCache;
        _queuedTasks = [NSMutableArray array];
        _mergedTasks = [NSMutableDictionary dictionary];
        _activeTaskCount = 0;
        _decodeImageInBackground = YES;
        NSString *name = [NSString stringWithFormat:@"com.heyang.imagedownloader.synchronizationqueue-%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        name = [NSString stringWithFormat:@"com.heyang.imagedownloader.responsequeue-%@", [[NSUUID UUID] UUIDString]];
        self.responseQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
        name = [NSString stringWithFormat:@"com.heyang.imagedownloader.decodequeue-%@", [[NSUUID UUID] UUIDString]];
         self.decodeQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);

    }
    return self;
}


-(HYImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)URLRequest withReceiptID:(NSUUID *)receiptID success:(void (^)(NSURLRequest *, NSHTTPURLResponse *, UIImage *))succss failure:(void (^)(NSURLRequest *, NSHTTPURLResponse *, NSError *))failure options:(HYImageDownloaderOptions)options{
    

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
        //解决URL相同的时候不是同一个task导致回调不一致的问题
        HYImageDownloadMergedTask *exsitingMergedTask = self.mergedTasks[URLIdentifier];
        if (exsitingMergedTask) {
            HYImageResponseHandler *handler = [[HYImageResponseHandler alloc] initWithUUID:receiptID success:succss failure:failure];
            [exsitingMergedTask.responseHandlers addObject:handler];
            task = exsitingMergedTask.task;
            
            return;
        }
        //尝试从缓存中取图片并调用success
        if (!(options & HYImageDownloaderOptionsIgnoreCache)) {
            switch (URLRequest.cachePolicy) {
                case NSURLRequestUseProtocolCachePolicy:
                case NSURLRequestReturnCacheDataElseLoad:
                case NSURLRequestReturnCacheDataDontLoad:{
                    UIImage *image = [self.imageCache objectForKey:URLIdentifier];
                    if (image) {
                        
                        if (succss) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                succss(URLRequest,nil,image);
                            });
                        }
                        
                        return;
                    }
                    
                }
                    break;
                    
                default:
                    break;
            } 
        }
 

      //创建新的task
       NSURLSessionDataTask *createdTask = [self.session dataTaskWithRequest:URLRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

           dispatch_async(self.responseQueue, ^{

               HYImageDownloadMergedTask *mergeTask = self.mergedTasks[URLIdentifier];
               
               if (mergeTask) {
                   [self removeMergedTaskWithURLIdentifier:URLRequest.URL.absoluteString];
                   if (error) {
                       dispatch_async(dispatch_get_main_queue(), ^{
                           for (HYImageResponseHandler *hander in mergeTask.responseHandlers) {
                                   hander.failureBlock(URLRequest,nil,error);
                           }
                       });
                   }else{
                       UIImage *image = [UIImage imageWithData:data];

                       if (_decodeImageInBackground) {
                        dispatch_async(_decodeQueue, ^{
                            UIImage *decodeImage = [image imageByDecoded];
                            [self.imageCache setObject:decodeImage withKey:URLIdentifier];

                            dispatch_async(dispatch_get_main_queue(), ^{
                                for (HYImageResponseHandler *handler in mergeTask.responseHandlers) {
                                    handler.successBlock(URLRequest,(NSHTTPURLResponse *)response,decodeImage);
                                }
                                
                            });
                        });
                           
                       }else{
                           if (image) {
                               [self.imageCache setObject:image withKey:URLIdentifier];
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   for (HYImageResponseHandler *handler in mergeTask.responseHandlers) {
                                       handler.successBlock(URLRequest,(NSHTTPURLResponse *)response,image);
                                   }
                                   
                               });
                           }
                       }
                 
                       
                   }
                   dispatch_async(self.synchronizationQueue, ^{
                       self.activeTaskCount--;
                       [self chooseTaskToExcute];
                       
                   });
                   
               }
           });
      
        }];
        //将task与success和failure的回调进行绑定
        HYImageResponseHandler *handler = [[HYImageResponseHandler alloc] initWithUUID:receiptID success:succss failure:failure];
        HYImageDownloadMergedTask *mergedTask = [[HYImageDownloadMergedTask alloc]initWithURLIdentifier:URLRequest.URL.absoluteString UIIDIdentifier:receiptID task:createdTask responseHandlers:[NSMutableArray array]];
        [mergedTask.responseHandlers addObject:handler];
        self.mergedTasks[URLIdentifier] = mergedTask;
        task = mergedTask.task;
        [self queueOrExcuteTask:mergedTask];

    });
    
    if (task) {
        HYImageDownloadReceipt *receipt = [[HYImageDownloadReceipt alloc] initWithReceipt:receiptID sessionTask:task];
        return receipt;
    }else{
        return nil;
    } 
}

-(void)cancelTaskWithURLRequest:(NSURLRequest *)URLRequest{
    dispatch_async(self.synchronizationQueue, ^{
        [self.mergedTasks removeObjectForKey:URLRequest.URL.absoluteString];
        NSMutableArray *cancelledTasksArray = [NSMutableArray array];
        for (HYImageDownloadMergedTask *task in self.queuedTasks) {
            if ([task.URLIdentifier isEqualToString:URLRequest.URL.absoluteString]) {
                [cancelledTasksArray addObject:task];
            }
        }
        [self.queuedTasks removeObjectsInArray:cancelledTasksArray];
    });
}


-(void)cancelTaskWithReceipt:(HYImageDownloadReceipt *)receipt{
    dispatch_sync(self.synchronizationQueue, ^{
        NSString *URLIdentifier = receipt.task.originalRequest.URL.absoluteString;
        HYImageDownloadMergedTask *mergedTask = self.mergedTasks[URLIdentifier];
        NSInteger index;
        if (mergedTask) {
            index = [mergedTask.responseHandlers indexOfObjectPassingTest:^BOOL(HYImageResponseHandler *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return  obj.uuid = receipt.receipitID;
            }];
        }
        if (index != NSNotFound) {
            HYImageResponseHandler *handler = mergedTask.responseHandlers[index];
            [mergedTask.responseHandlers removeObject:handler];
            NSString *failureString = [NSString stringWithFormat:@"Cancel the task with URLRequest %@",URLIdentifier];
            NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey:failureString};
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
            if (handler.failureBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler.failureBlock(receipt.task.originalRequest,nil,error);
                });
            }
            
            if (mergedTask.responseHandlers.count == 0 && mergedTask.task.state == NSURLSessionTaskStateSuspended) {
                [mergedTask.task cancel];
                [self.mergedTasks removeObjectForKey:URLIdentifier];
            }
            
        }
    });
 
}

- (void)removeMergedTaskWithURLIdentifier:(NSString *)URLIdentifier{
    dispatch_async(self.synchronizationQueue, ^{
        [self.mergedTasks removeObjectForKey:URLIdentifier];
    });
}


- (void)queueOrExcuteTask:(HYImageDownloadMergedTask *)mergedTask{
   dispatch_async(self.synchronizationQueue, ^{
       if (self.activeTaskCount < self.maxDownloadCount) {
           [self excuteNextTask:mergedTask];
          
       }else{
           [self.queuedTasks addObject:mergedTask];
       }
   });

    
}

- (void)excuteNextTask:(HYImageDownloadMergedTask *)mergedTask{
    [mergedTask.task resume];
    self.activeTaskCount++;
    
}


- (void)chooseTaskToExcute{
    if (self.queuedTasks.count <= 0) return;
    
    switch (self.downloadPrioritization) {
        case HYImageDownloadFIFO:{
            
            HYImageDownloadMergedTask *task = self.queuedTasks[0];
            [self.queuedTasks removeObjectAtIndex:0];
            [self excuteNextTask:task];
        }
            break;
        case HYImageDownloadFILO:{
            HYImageDownloadMergedTask *task = [self.queuedTasks lastObject];
            [self.queuedTasks removeObjectAtIndex:self.queuedTasks.count - 1];
            [self excuteNextTask:task];

        }
        default:
            break;
    }
}



@end
