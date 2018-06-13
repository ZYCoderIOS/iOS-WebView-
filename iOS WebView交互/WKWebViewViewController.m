//
//  WKWebViewViewController.m
//  iOS WebView交互
//
//  Created by Liqu on 2018/6/13.
//  Copyright © 2018年 Liqu. All rights reserved.
//

#import "WKWebViewViewController.h"
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <MJExtension.h>
#import "YYWeakProxy.h"
#import "UserInfo.h"

@interface WKWebViewViewController ()<WKScriptMessageHandler,WKUIDelegate>
@property (nonatomic,strong) WKWebView *webView;
@end

@implementation WKWebViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"WKWebView";
    [self.view addSubview:self.webView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"OC调用JS方法" style:0 target:self action:@selector(ocCallJSMethod)];
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.userContentController = [[WKUserContentController alloc]init];
        YYWeakProxy <WKScriptMessageHandler>*proxy = (id<WKScriptMessageHandler>)[YYWeakProxy proxyWithTarget:self];
        [configuration.userContentController addScriptMessageHandler:proxy name:@"liqu_app"];
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        _webView.UIDelegate = self;
        NSURL *localHTMLURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"WKWebViewJSInteraction" ofType:@"html"]];
        NSURLRequest *request = [NSURLRequest requestWithURL:localHTMLURL];
        [_webView loadRequest:request];
    }
    return _webView;
}


- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    // 根绝对应的name和body执行对应的逻辑
    NSLog(@"%@   ---    %@",message.body,message.name);
    
    // deal
    if ([message.body isEqualToString:@"fetchUserInfo"]) {
        [self ocCallJSMethod];
    }else {
        
    }
}

- (void)ocCallJSMethod {
    
    UserInfo *info = [UserInfo new];
    info.name = @"liqu";
    info.age = 18;
    NSString *jsMethod = [NSString stringWithFormat:@"ocCallJSMethod('%@')",[info mj_JSONString]];
    
    [_webView evaluateJavaScript:jsMethod
               completionHandler:^(id _Nullable obj, NSError * _Nullable
                                   error)
    {
        NSLog(@"%@",obj);
    }];
}

- (void)dealloc {
    NSLog(@"WKWebViewViewController is dealloc");
}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:0 handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
    completionHandler();
}
@end
