//
//  SharkImageViewController.m
//  Shark Feed
//
//  Created by Molly Tian on 8/13/16.
//  Copyright © 2016 Molly Tian. All rights reserved.
//

#import "SharkImageViewController.h"
#import "FlickrURL.h"
#import "FlickrPageWebViewController.h"

@interface SharkImageViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (nonatomic, strong) NSDictionary *photoInfo;
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation SharkImageViewController

#pragma mark - Properties

@synthesize imageView = _imageView;

- (UIImageView *)imageView
{
    if (!_imageView) _imageView = [[UIImageView alloc] init];
    return _imageView;
}

- (void)setImageView:(UIImageView *)imageView {
    _imageView = imageView;
    self.scrollView.contentSize = self.imageView.image ? self.imageView.image.size : CGSizeZero;
}

- (void)setScrollView:(UIScrollView *)scrollView
{
    _scrollView = scrollView;
    
    _scrollView.minimumZoomScale = 1;
    _scrollView.maximumZoomScale = 2.5;
    _scrollView.delegate = self;
    
}

- (void)setPhoto:(NSDictionary *)photo
{
    _photo = photo;
    [self startDownloadingImage];
}

- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration];
    }
    return _session;
}

- (void)setPhotoInfo:(NSDictionary *)photoInfo {
    _photoInfo = photoInfo;
    [self setDescriptionLabelText];
}



#pragma mark - UIScrollViewDelegate

// mandatory zooming method in UIScrollViewDelegate protocol

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.descriptionLabel.hidden = true;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Custom Functions

- (void) setDescriptionLabelText {
    if ([self.photoInfo valueForKeyPath:@"description._content"] != nil) {
        self.descriptionLabel.text = [self.photoInfo valueForKeyPath:@"description._content"];
        self.descriptionLabel.hidden = false;
    }
}

- (IBAction)tappedImage:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        if ([[self navigationController] isNavigationBarHidden]) {
            [[self navigationController] setNavigationBarHidden:NO animated:YES];
        } else {
            [[self navigationController] setNavigationBarHidden:YES animated:YES];
        }
    }
}

- (void)startDownloadingImage
{
    self.imageView.image = nil;
    __block Boolean largeImageLoaded = false;
    if (self.photo)
    {
        // Load low quality photo
        NSURL *smallImageURL = [FlickrURL URLforPhoto:self.photo format:FlickrPhotoFormatSmall];
        NSURLRequest *smallImageRequest = [NSURLRequest requestWithURL:smallImageURL];
        NSURLSessionDownloadTask *smallPhotoTask = [self.session downloadTaskWithRequest:smallImageRequest
                                                                  completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                                                                      if ([[FlickrURL URLforPhoto:self.photo format:FlickrPhotoFormatSmall] isEqual:smallImageRequest.URL]) {
                                                                          if (smallImageURL) {
                                                                              UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localfile]];
                                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                                  
                                                                                  if (!largeImageLoaded)
                                                                                      self.imageView.image = image;
                                                                              });
                                                                          }
                                                                      }
                                                                  }];
        [smallPhotoTask resume];
        
        //load larger photo
        NSURL *imageURL = [FlickrURL URLforPhoto:self.photo format:FlickrPhotoFormatLarge];
        NSURLRequest *photoRequest = [NSURLRequest requestWithURL:imageURL];
        NSURLSessionDownloadTask *photoTask = [self.session downloadTaskWithRequest:photoRequest
                                                        completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                                                            if ([[FlickrURL URLforPhoto:self.photo format:FlickrPhotoFormatLarge] isEqual:photoRequest.URL]) {
                                                                if (imageURL) {
                                                                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localfile]];
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        
                                                                        [UIView transitionWithView:self.imageView
                                                                                          duration:1.0f
                                                                                           options:UIViewAnimationOptionTransitionCrossDissolve
                                                                                        animations:^{
                                                                                            self.imageView.image = image;
                                                                                            largeImageLoaded = true;
                                                                                        } completion:nil];
                                                                        
                                                                    });
                                                                }
                                                            }
                                                        }];
        [photoTask resume];
        
        NSURL *infoURL = [FlickrURL URLforPhotoInformation: [self.photo valueForKey:@"id"]];
        NSURLSessionDataTask *photoInfoTask = [self.session dataTaskWithURL:infoURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                 if (!error) {
                                                                     NSDictionary *propertyListResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                                                                     NSDictionary *photoInfo = [propertyListResults valueForKey:@"photo"];
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                         self.photoInfo = photoInfo;
                                                                     });
                                                                 }
                                                             }];
        [photoInfoTask resume];

    }
}





- (IBAction)download:(UIButton *)sender {
    UIImageWriteToSavedPhotosAlbum(self.imageView.image, nil, nil, nil);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Photo saved to camera roll"
                                                                             message:@""
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alertController addAction:actionOk];
    [self presentViewController:alertController animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alertController dismissViewControllerAnimated:true completion:nil];
    });
}




#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"OpenInFlickr"]) {
        if ([segue.destinationViewController isKindOfClass:[FlickrPageWebViewController class]]) {
            FlickrPageWebViewController *webVC = segue.destinationViewController;
            NSArray *urls = [self.photoInfo valueForKeyPath:@"urls.url"];
            NSString *urlString = [[urls firstObject] valueForKey:@"_content"];
            NSURL *url = [NSURL URLWithString:urlString];
            webVC.url = url;
        }
    }
    
}


@end
