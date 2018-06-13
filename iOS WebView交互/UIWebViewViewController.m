//
//  UIWebViewViewController.m
//  iOS WebView交互
//
//  Created by Liqu on 2018/6/13.
//  Copyright © 2018年 Liqu. All rights reserved.
//

#import "UIWebViewViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <ReactiveCocoa.h>
#import "YYWeakProxy.h"
#import "UserInfo.h"
#import <MJExtension.h>

@protocol  UIWebViewJSExport <JSExport>
// 注意:此处一定不要写@optional,否则js不会回调协议里面的方法
//@optional
- (void)jsInvokeOCNoParm;
- (void)jsInvokeOCWithParm1:(NSString *)parm1;
- (void)jsInvokeOCWithParm1:(NSString *)parm1 parm2:(NSString *)parm2;
- (NSString *)jsInvokeOCReturnValue;
@end

@interface UIWebViewViewController ()<UIWebViewJSExport,UIWebViewDelegate>
@property (nonatomic,strong) UIWebView *webView;
@property (nonatomic,strong) JSContext *context;
@end

@implementation UIWebViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"UIWebView";
    
    [self.view addSubview:self.webView];
    
    @weakify(self)
    [[self.webView rac_valuesForKeyPath:@"documentView.webView.mainFrame.javaScriptContext" observer:self] subscribeNext:^(id x) {
        @strongify(self)
        JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
        YYWeakProxy *proxy = [YYWeakProxy proxyWithTarget:self];
        [context setObject:proxy forKeyedSubscript:@"liqu_app"];
        self.context = context;
    }];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"OC调用JS方法" style:0 target:self action:@selector(ocCallJSMethod)];
}

- (UIWebView *)webView {
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.delegate = self;
        NSURL *localHTMLURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"UIWebViewJSInteraction" ofType:@"html"]];
        NSURLRequest *request = [NSURLRequest requestWithURL:localHTMLURL];
        [_webView loadRequest:request];
    }
    return _webView;
}

#pragma mark -UIWebViewDelegate
/*
 不推荐使用这个方法注册js对象,这个方法会在<script></script>标签走完之后调用,也就是说无法再这个标签内部拿到注册的js对象
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    YYWeakProxy *proxy = [YYWeakProxy proxyWithTarget:self];
    [context setObject:proxy forKeyedSubscript:@"liqu_app"];
}
*/

#pragma mark -UIWebViewJSExport
- (void)jsInvokeOCNoParm {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)jsInvokeOCWithParm1:(NSString *)parm1 {
    NSLog(@"%@,parm:%@",NSStringFromSelector(_cmd),parm1);
}

- (void)jsInvokeOCWithParm1:(NSString *)parm1 parm2:(NSString *)objStr {
    //objStr 从html传出对象到oc,这事一个字符串,需要我们转成oc对象
    NSData *data = [objStr dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSLog(@"%@,parm1:%@ parm2:%@",NSStringFromSelector(_cmd),parm1,obj);
}

// 从本地获取信息到HTML
- (NSString *)jsInvokeOCReturnValue {
    UserInfo *info = [UserInfo new];
    info.name = @"liqu";
    info.age = 18;
    // 对象转字符串(实现Android和iOS逻辑统一)
    NSString *json = [info mj_JSONString];
    return json;
}

#pragma mark -oc调用js方法
- (BOOL)ocCallJSMethod {

    // 方式1:
    UserInfo *info = [UserInfo new];
    info.name = @"liqu";
    info.age = 18;
    JSValue *jsResult = [self.context evaluateScript:[NSString stringWithFormat:@"ocCallJSMethod('%@')",[info mj_JSONString]]];
    BOOL result = [jsResult toBool];
    NSLog(@"%d",result);
    
    //方式2:
    {
        JSValue *ocInvokeJs = self.context[@"ocCallJSMethod"];
        JSValue *jsResult = [ocInvokeJs callWithArguments:@[[info mj_JSONString]]];
        BOOL result = [jsResult toBool];
        NSLog(@"%d",result);
    }
    return result;
}

- (void)dealloc {
    NSLog(@"UIWebViewViewController is dealloc");
}
@end
