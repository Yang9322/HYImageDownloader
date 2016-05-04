//
//  ViewController.m
//  HYImageDownloader
//
//  Created by He yang on 16/5/1.
//  Copyright © 2016年 He yang. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+HYImageDownloader.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView0;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_imageView0 hy_setImageWithURLString:@"http://e.hiphotos.baidu.com/image/h%3D200/sign=3ef3e55ee7fe9925d40c6e5004a95ee4/8694a4c27d1ed21b0a2ed37eaa6eddc450da3f41.jpg" placeHolder:[UIImage imageNamed:@"36_2"]];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
