//
//  TCSinglePageWebViewController.m
//  InterestingThings
//
//  Created by Christopher Trott on 2/12/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSSinglePageWebViewController.h"

@interface TCSSinglePageWebViewController ()

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIButton *closeButton;

@property (getter = isLocal) BOOL local;
@property (strong) NSString *remoteURL;
@property (strong) NSString *localFileName;

@end

@implementation TCSSinglePageWebViewController

- (id)initWithRemoteURLString:(NSString *)remoteURL{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.remoteURL = remoteURL;
    self.local = NO;
  }
  return self;
}

- (id)initWithLocalHTMLFileName:(NSString *)htmlFileNameWithoutExtension{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.localFileName = htmlFileNameWithoutExtension;
    self.local = YES;
  }
  return self;
}


- (void)loadView{
  self.view = [[UIView alloc] init];
  self.view.backgroundColor = WHITE_SUBTLE;
  self.view.autoresizesSubviews = YES;
}

- (void)viewDidLoad{
  [super viewDidLoad];

  self.webView = [[UIWebView alloc] init];
  self.webView.delegate = self;
  self.webView.scalesPageToFit = NO;
  self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
  
  self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
  [self.closeButton setTitleColor:GRAYACOLOR(45, 0.3f) forState:UIControlStateNormal];
  [self.closeButton setTitleColor:WHITE forState:UIControlStateHighlighted];
  [self.closeButton.titleLabel setFont:[UIFont systemFontOfSize:30]];
  [self.closeButton.titleLabel setShadowColor:BLACK];
  [self.closeButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
  [self.closeButton addTarget:self action:@selector(doClose:) forControlEvents:UIControlEventTouchUpInside];
  self.closeButton.frame = CGRectMake(0, 0, 40, 40);
  
  [self.view addSubview:self.webView];
  [self.view addSubview:self.closeButton];
}

- (void)viewDidAppear:(BOOL)animated{
  if (self.local){
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:self.localFileName ofType:@"html" inDirectory:nil];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    if (!htmlFile || !htmlString){
      DLog(@"Error loading html file");
    }else{
      [self.webView loadHTMLString:htmlString baseURL:nil];
    }
  }else{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.remoteURL]];
    [self.webView loadRequest:request];
  }
}

- (void)viewWillLayoutSubviews{
  CGFloat hButtonMargin = 2;
  CGFloat vButtonMargin = 14;
  self.webView.frame = self.view.bounds;
  self.closeButton.right = self.view.right - hButtonMargin;
  self.closeButton.top = self.view.bounds.origin.y + vButtonMargin;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

- (void)doClose:(UIButton *)button{
  [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
  DLog(@"Error loading webview page");
}

@end
