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
#import "SDWebImage/UIImageView+WebCache.h"
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController{
    NSMutableDictionary *dic;
    NSMutableArray *array;
}
- (IBAction)clicked:(id)sender {
    

    
    


}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
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
    
    NSMutableArray *ayy = [NSMutableArray array];
    dic = [NSMutableDictionary dictionary];
    dic[@"param"] = ayy;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Do any additional setup after loading the view, typically from a nib.
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return array?100:0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 47;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:@"defulat"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"defulat"];
    }
    NSInteger integer = indexPath.row % 7;
    [cell.imageView hy_setImageWithURLString:array[integer] placeHolder:[UIImage imageNamed:@"36_2"]];
//    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:array[integer]] placeholderImage:[UIImage imageNamed:@"36_2"]];
    return cell;
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
