//
//  FlickrPageWebViewController.m
//  Shark Feed
//
//  Created by Molly Tian on 8/15/16.
//  Copyright © 2016 Molly Tian. All rights reserved.
//

#import "FlickrPageWebViewController.h"

@interface FlickrPageWebViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation FlickrPageWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    [self.webView loadRequest:request];
    
}


// added this method otherwise it will have memory leak
- (void)dealloc {
    self.webView = nil;
    //[super dealloc];
}




@end
