//
//  ViewController.m
//  AliPayDemo
//
//  Created by James Hsu on 8/11/15.
//  Copyright (c) 2015 James Hsu. All rights reserved.
//

#import "ViewController.h"

#import <AlipaySDK/AlipaySDK.h>
#import "AFNetworking.h"

@interface ViewController () <UIActionSheetDelegate>

@property (nonatomic, weak) UIButton *btn;

@property (nonatomic, weak) UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UITextField *txt = [[UITextField alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 0.5 - 50, self.view.frame.size.height * 0.5 - 150, 100, 30)];
    txt.backgroundColor = [UIColor lightGrayColor];
    txt.borderStyle = UITextBorderStyleRoundedRect;
    txt.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    [txt addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:txt];
    self.textField = txt;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"支付金额:";
    label.frame = CGRectMake(CGRectGetMinX(self.textField.frame) - 80, self.view.frame.size.height * 0.5 - 150, 100, 30);
    [self.view addSubview:label];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(self.view.frame.size.width * 0.5 - 25, self.view.frame.size.height * 0.5 - 25, 50, 50);
    [btn setBackgroundColor:[UIColor redColor]];
    [btn setTitle:@"支付" forState: UIControlStateNormal];
    btn.layer.cornerRadius = 25;
    btn.layer.masksToBounds = YES;
    [btn addTarget:self action:@selector(alertView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    self.btn = btn;
}

-(void)textFieldDidChange:(id)sender
{
    NSLog(@"%@", self.textField.text);

    if ([self.textField.text isEqualToString:@""]) {
        [self.btn setBackgroundColor:[UIColor redColor]];
    } else {
        [self.btn setBackgroundColor:[UIColor greenColor]];
    }
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self btnClick];/**< 支付 */
    } else {
        return;
    }
}

/**
 *  弹出支付框
 */
- (void)alertView
{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"确认支付 %@ 元", self.textField.text] delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"支付" otherButtonTitles:nil, nil];
    [action showInView:self.view];
}

/**
 *  支付
 */
- (void)btnClick
{
    NSDictionary *parameters = @{@"payment_id":@"1",
                                 @"paylist_id":@"1",
                                 @"buyer_id":@"1",
                                 @"buyer_name":@"james",
                                 @"goods_amount":self.textField.text,
                                 @"type":@"json"};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    
    [manager POST:@"接口地址" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject options:0 error:nil];
        
        NSString *requestParameter = [dic objectForKey:@"data"];
        
        // 返回签名的字符串
        NSLog(@"data-->%@", requestParameter);
        
        // 请求支付宝服务器
        NSString *appScheme = @"AliPayDemo";
        
        [[AlipaySDK defaultService] payOrder:requestParameter fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"reslut --> %@", resultDic);

            NSString *resultStatus = nil;
            NSString *result = nil;
            // 遍历所有字符串
            for (NSString *key in resultDic) {
                NSString *obj = [resultDic objectForKey:key];
                NSLog(@"obj-->%@", obj);
            }
            
            resultStatus = [resultDic objectForKey:@"resultStatus"];
            NSLog(@"resultStatus-->%@", resultStatus);
            
            result = [resultDic objectForKey:@"result"];
            NSLog(@"resultOld-->%@", result);   
            
            if ([resultStatus isEqualToString:@"9000"]) {

                NSRange range = [result rangeOfString:@"true"];
                result = [result substringWithRange:range];
                NSLog(@"resultNew-->%@", result);

                if ([result isEqualToString:@"true"]) {
                    NSLog(@"订单支付成功");
                    [self enterAlertView:@"支付成功"];
                    [self textFieldDidChange:self.textField];
                    return;
                }
                
            } else if ([resultStatus isEqualToString:@"8000"]) {
                NSLog(@"正在处理中");
                [self enterAlertView:@"支付处理中"];
                
            } else if ([resultStatus isEqualToString:@"4000"]) {
                NSLog(@"订单支付失败");
                [self enterAlertView:@"订单支付失败"];
                
            } else if ([resultStatus isEqualToString:@"6001"]) {
                NSLog(@"用户中途取消");
                [self enterAlertView:@"用户取消"];
                
            } else if ([resultStatus isEqualToString:@"6002"]) {
                NSLog(@"网络连接出错");
                [self enterAlertView:@"网络连接出错"];
            }
            
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

/**
 *  支付状态
 *
 *  @param message 状态名称
 */
- (void)enterAlertView:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

@end
