//
//  HorizontalScreenVC.m
//
//
//  Created by 罗欣 on 16/1/18.
//  Copyright © 2016年 Useus. All rights reserved.
//

#import "HorizontalScreenVC.h"

@interface HorizontalScreenVC ()

@end
//此控制器只用来作为播放器的父类控制只支持横屏
@implementation HorizontalScreenVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

//只支持横屏
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape ;
}
//不支持自动旋转
- (BOOL)shouldAutorotate
{
    return YES;
}
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeRight;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
