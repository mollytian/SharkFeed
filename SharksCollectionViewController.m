//
//  SharksCollectionViewController.m
//  Shark Feed
//
//  Created by Molly Tian on 8/13/16.
//  Copyright © 2016 Molly Tian. All rights reserved.
//

#import "SharksCollectionViewController.h"
#import "SharkCollectionViewCell.h"
#import "FlickrURL.h"
#import "SharkImageViewController.h"
#import <QuartzCore/QuartzCore.h>


@interface SharksCollectionViewController ()

@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UIView *refreshControlView;
@property (strong, nonatomic) NSNumber *pages;

@end

@implementation SharksCollectionViewController

static NSString * const reuseIdentifier = @"SharkImageCell";
static NSString * const searchString = @"shark";
static NSString * const viewTitle = @"SharkFeed";

#pragma mark - Properties

@synthesize photos = _photos;

- (NSMutableArray *)photos {
    if (!_photos) {
        _photos = [[NSMutableArray alloc] init];
    }
    return _photos;
    
}

- (void)setPhotos:(NSMutableArray *)photos
{
    _photos = photos;
    [self.refreshControl endRefreshing];
    [self.collectionView reloadData];
}

- (NSNumber *)pages {
    if (!_pages) {
        _pages = [NSNumber numberWithInt:1];
    }
    return _pages;
}

#pragma mark - Custom Functions

- (void)refresh {
    [self fetchPhotosOfPage:[NSNumber numberWithInt:1] isRefreshing:YES];
}

- (IBAction)fetchPhotosOfPage:(NSNumber *) page isRefreshing:(BOOL)iSRefreshing
{
    NSURL *url = [FlickrURL URLforSearchString:searchString ofPage:page];
    
    [self.refreshControl beginRefreshing];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      NSDictionary *propertyListResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                                      NSArray *photos = [propertyListResults valueForKeyPath:FLICKR_RESULTS_PHOTOS];
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          if (iSRefreshing) {
                                              self.photos = [photos mutableCopy];
                                          } else {
                                              [self.photos addObjectsFromArray: photos];
                                          }
                                          [self.collectionView reloadData];
                                          [self.refreshControl endRefreshing];
                                      });
                                  }];
    [task resume];
}

- (void)loadCustomRefreshContents {
    NSArray *contents = [[NSBundle mainBundle] loadNibNamed:@"Refresh Control" owner:self options:nil];
    self.refreshControlView = [contents firstObject];
    self.refreshControlView.frame = _refreshControl.bounds;
    self.refreshControlView.clipsToBounds = YES;
    [self.refreshControl addSubview:self.refreshControlView];
}

- (void)spinView: (UIView *)view WithOptions: (UIViewAnimationOptions) options {
    [UIView animateWithDuration: 0.001f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         view.transform = CGAffineTransformRotate(view.transform, M_PI / 2);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if ([self.refreshControl isRefreshing]) {
                                 // if flag still set, keep spinning with constant speed
                                 [self spinView:view WithOptions:UIViewAnimationOptionCurveLinear];
                             } else if (options != UIViewAnimationOptionCurveEaseOut) {
                                 // one last spin, with deceleration
                                 [self spinView:view WithOptions:UIViewAnimationOptionCurveEaseOut];
                             }
                         }
                     }];
}

- (void)refreshControlStartSpinning {
    UIImageView *fishhookView = (UIImageView *)[[[[[[self.refreshControlView subviews] firstObject] subviews] firstObject] subviews] firstObject];
    [self spinView:fishhookView WithOptions:UIViewAnimationOptionCurveEaseIn];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = viewTitle;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor clearColor];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    [self loadCustomRefreshContents];
    
    self.collectionView.alwaysBounceVertical = YES;
    [self fetchPhotosOfPage:[NSNumber numberWithInt:1] isRefreshing:YES];
    [self refreshControlStartSpinning];
}



#pragma mark - Navigation


- (void)prepareImageViewController:(SharkImageViewController *)sivc toDisplayPhoto:(NSDictionary *)photo
{
    sivc.photo = photo;
    sivc.title = [photo valueForKeyPath:FLICKR_PHOTO_TITLE];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UICollectionViewCell class]]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"DisplayPhoto"]) {
                if ([segue.destinationViewController isKindOfClass:[SharkImageViewController class]]) {
                    [self prepareImageViewController:segue.destinationViewController toDisplayPhoto:self.photos[indexPath.row]];
                }
            }
        }
    }
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.photos count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SharkCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageNamed:@"placeholder"];
    NSDictionary *photo = self.photos[indexPath.row];
    NSURL *thumbnailUrl = [FlickrURL URLforPhoto:photo format:FlickrPhotoFormatSmall];
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:thumbnailUrl completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            UIImage *image = [UIImage imageWithData:data];
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    SharkCollectionViewCell *updateCell = (id)[collectionView cellForItemAtIndexPath:indexPath];
                    if (updateCell)
                        updateCell.imageView.image = image;
                });
            }
        }
    }];
    [task resume];
    
    cell.backgroundColor = [UIColor blueColor];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.photos.count - 1) {
        self.pages = [NSNumber numberWithInt:[self.pages intValue] + 1];
        [self fetchPhotosOfPage:self.pages isRefreshing:NO];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self.refreshControl isRefreshing]) {
        [self refreshControlStartSpinning];
    }
}

#pragma mark - Collection view layout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat cellSize = 0;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if(orientation == 0 || orientation == UIInterfaceOrientationPortrait){
        cellSize = self.view.bounds.size.width / 3 - 4;
    } else if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        cellSize = self.view.bounds.size.width / 5 - 15;
    }
    
    CGSize mElementSize = CGSizeMake(cellSize, cellSize);
    return mElementSize;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 4;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 4;
}

// Layout: Set Edges
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(2,2,2,2);  // top, left, bottom, right
}


@end


