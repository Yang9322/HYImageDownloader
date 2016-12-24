//
//  ViewController.m
//  HYImageDownloader
//
//  Created by He yang on 16/5/1.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+HYImageDownloader.h"
#import "HYFPSLabel.h"
#import "CustomCell.h"
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate,NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong)dispatch_queue_t synchronizationQueue;
@property (nonatomic,strong)dispatch_queue_t concurrentQueue;

@end

@implementation ViewController{
    NSMutableDictionary *dic;
    NSMutableArray *array;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    
}


- (IBAction)clicked:(id)sender {
    

  
    


}




-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    NSURLSession *ssion = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
//
//    NSURLSessionDataTask *task = [ssion dataTaskWithURL:[NSURL URLWithString:@"ttp://b.hiphotos.baidu.com/image/h%3D200/sign=52b5924e8b5494ee982208191df4e0e1/c2fdfc039245d6887554a155a3c27d1ed31b24e8.jpg"]];
//    [task resume];
//    
//    return;
    NSString *str = @"http://b.hiphotos.baidu.com/image/h%3D200/sign=52b5924e8b5494ee982208191df4e0e1/c2fdfc039245d6887554a155a3c27d1ed31b24e8.jpg";
    NSString *str2 = @"http://g.hiphotos.baidu.com/image/h%3D200/sign=70676361b41c8701c9b6b5e6177e9e6e/8644ebf81a4c510f87ed3f9f6759252dd42aa50e.jpg";
    NSString *str3 = @"http://e.hiphotos.baidu.com/image/h%3D200/sign=3ef3e55ee7fe9925d40c6e5004a95ee4/8694a4c27d1ed21b0a2ed37eaa6eddc450da3f41.jpg";
    NSString *str4 = @"http://g.hiphotos.baidu.com/image/h%3D200/sign=875ef8ffb63533faeab6942e98d2fdca/0eb30f2442a7d93356139582aa4bd11372f00183.jpg";
    NSString *str5 = @"http://f.hiphotos.baidu.com/image/h%3D300/sign=2098edd24e540923b569657ea259d1dc/dcc451da81cb39db1bd474a7d7160924ab18302e.jpg";
    NSString *str6 = @"http://b.hiphotos.baidu.com/image/h%3D300/sign=b71da383abaf2eddcbf14fe9bd110102/bd3eb13533fa828b670a4066fa1f4134970a5a0e.jpg";
    NSString *str7 = @"http://d.hiphotos.baidu.com/image/h%3D200/sign=880f94d09413b07ea2bd57083cd59113/5fdf8db1cb1349547adefb95514e9258d0094a7a.jpg";
    
    array = [NSMutableArray arrayWithObjects:str,str2,str3,str4,str5,str6,str7,nil];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    HYFPSLabel *label = [[HYFPSLabel alloc] init];
    label.bounds = CGRectMake(0, 0, 80, 40);
    label.center = CGPointMake([UIScreen mainScreen].bounds.size.width - 40, [UIScreen mainScreen].bounds.size.height - 20);
    [self.view addSubview:label];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    NSString *name = [NSString stringWithFormat:@"com.heyang.imagedownloader.synchronizationqueue-%@", [[NSUUID UUID] UUIDString]];
    self.synchronizationQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
     name = [NSString stringWithFormat:@"com.heyang.imagedownloader.concurrentQueue-%@", [[NSUUID UUID] UUIDString]];
    self.concurrentQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    [[HYImageDownloader shareInstance].imageCache removeAll];
//    [self addObserver];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)addObserver {
    
    // 1. 创建监听者
    /**
     *  创建监听者
     *
     *  @param allocator#>  分配存储空间
     *  @param activities#> 要监听的状态
     *  @param repeats#>    是否持续监听
     *  @param order#>      优先级, 默认为0
     *  @param observer     观察者
     *  @param activity     监听回调的当前状态
     */
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopBeforeWaiting, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        
        /*
         kCFRunLoopEntry = (1UL << 0),          进入工作
         kCFRunLoopBeforeTimers = (1UL << 1),   即将处理Timers事件
         kCFRunLoopBeforeSources = (1UL << 2),  即将处理Source事件
         kCFRunLoopBeforeWaiting = (1UL << 5),  即将休眠
         kCFRunLoopAfterWaiting = (1UL << 6),   被唤醒
         kCFRunLoopExit = (1UL << 7),           退出RunLoop
         kCFRunLoopAllActivities = 0x0FFFFFFFU  监听所有事件
         */
        switch (activity) {
            case kCFRunLoopEntry:
                NSLog(@"进入");
                break;
            case kCFRunLoopBeforeTimers:
                NSLog(@"即将处理Timer事件");
                break;
            case kCFRunLoopBeforeSources:
                NSLog(@"即将处理Source事件");
                break;
            case kCFRunLoopBeforeWaiting:
                NSLog(@"即将休眠事件");

                [self dispatchTasks];
                break;
            case kCFRunLoopAfterWaiting:
                NSLog(@"被唤醒");
                break;
            case kCFRunLoopExit:
                NSLog(@"退出RunLoop");
                break;
            default:
                break;
        }
    });
    

    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
}

- (void)dispatchTasks{
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return array?100:0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CustomCell *cell =[tableView dequeueReusableCellWithIdentifier:@"CustomCell"];
    
    if (!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"CustomCell" owner:nil options:nil] lastObject]; 
    }
    NSInteger integer = indexPath.row % 7;
    cell.markString = @"unresolved";
    [cell.customImageView hy_setImageWithURLString:array[integer] placeHolder:nil options:HYImageDowloaderOptionRoundedRect |HYImageDowloaderOptionFadeAnimation withCompletionBlock:^(UIImage *image, NSError *error) {
        if (image) {
            cell.markString = @"resolved";
   
        }

    }];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CustomCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSInteger integer = indexPath.row % 7;
    cell.markString = @"unresolved";
    [cell.customImageView hy_setImageWithURLString:array[integer] placeHolder:nil options:HYImageDowloaderOptionRoundedRect |HYImageDowloaderOptionFadeAnimation withCompletionBlock:^(UIImage *image, NSError *error) {
        if (image) {
            cell.markString = @"resolved";
            
        }
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
