//
//  RootViewController.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
//  Copyright (c) 2014, Andrew Krowczyk, Cédric Mériau, Pieter Claerhout
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of
//  conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials
//  provided with the distribution.
//  Neither the name of the Baker Framework nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <QuartzCore/QuartzCore.h>
#import <sys/xattr.h>
#import <AVFoundation/AVFoundation.h>

#import "BKREditBookViewController.h"
#import "BKRPageTitleLabel.h"
#import "BKRUtils.h"
#import "NSObject+BakerExtensions.h"
#import "UIScreen+BakerExtensions.h"


#define INDEX_FILE_NAME         @"index.html"

#define URL_OPEN_MODALLY        @"referrer=Baker"
#define URL_OPEN_EXTERNAL       @"referrer=Safari"

// Screenshots
#define MAX_SCREENSHOT_AFTER_CP  10
#define MAX_SCREENSHOT_BEFORE_CP 10

@implementation BKREditBookViewController

#pragma mark - INIT
- (id)initWithBook:(BKRBook *)bakerBook {

    self = [super init];
    if (self) {
        NSLog(@"[BakerView] Init book view...");
        
        _book = bakerBook;

        if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
            // Only available in iOS 7 +
            self.automaticallyAdjustsScrollViewInsets = NO;
        }

        // ****** DEVICE SCREEN BOUNDS
        screenBounds = [[UIScreen mainScreen] bounds];
        NSLog(@"[BakerView]     Device Screen (WxH): %fx%f.", screenBounds.size.width, screenBounds.size.height);

        // ****** SUPPORTED ORIENTATION FROM PLIST
        supportedOrientation = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];

        if (![[NSFileManager defaultManager] fileExistsAtPath:self.bkrCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.bkrCachePath withIntermediateDirectories:YES attributes:nil error:nil];
        }

        // ****** SCREENSHOTS DIRECTORY //TODO: set in load book only if is necessary
        defaultScreeshotsPath = [[self.bkrCachePath stringByAppendingPathComponent:@"screenshots"] stringByAppendingPathComponent:bakerBook.ID];

        // ****** STATUS FILE
        bookStatus = [[BKRBookStatus alloc] initWithBookId:bakerBook.ID];
        NSLog(@"[BakerView]     Status: page %@ @ scrollIndex %@px.", bookStatus.page, bookStatus.scrollIndex);

        // ****** Initialize audio session for html5 audio
//        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//        BOOL ok;
//        NSError *setCategoryError = nil;
//        ok = [audioSession setCategory:AVAudioSessionCategoryPlayback
//                                 error:&setCategoryError];
//        if (!ok) {
//            NSLog(@"[BakerView]     AudioSession - %s setCategoryError=%@", __PRETTY_FUNCTION__, setCategoryError);
//        }

        // ****** BOOK ENVIRONMENT
        pages  = [NSMutableArray array];
        toLoad = [NSMutableArray array];

        pageDetails = [NSMutableArray array];

        attachedScreenshotPortrait  = [NSMutableDictionary dictionary];
        attachedScreenshotLandscape = [NSMutableDictionary dictionary];

        tapNumber = 0;
        stackedScrollingAnimations = 0; // TODO: CHECK IF STILL USED!

        currentPageFirstLoading = YES;
        currentPageIsDelayingLoading = YES;
        currentPageHasChanged = NO;
        currentPageIsLocked = NO;
        currentPageWillAppearUnderModal = NO;

        userIsScrolling = NO;
        shouldPropagateInterceptedTouch = YES;
        shouldForceOrientationUpdate = YES;

        adjustViewsOnAppDidBecomeActive = NO;
        _barsHidden = YES;

        //webViewBackground = nil;

        pageNameFromURL = nil;
        anchorFromURL = nil;

        // TODO: LOAD BOOK METHOD IN VIEW DID LOAD
        [self loadBookWithBookPath:bakerBook.path];
    }
    return self;
}
- (void)viewDidLoad {

    [super viewDidLoad];
    self.navigationItem.title = self.book.title;
    
    
    // ****** SET THE INITIAL SIZE FOR EVERYTHING
    // Avoids strange animations when opening
    [self setPageSize:[self getCurrentInterfaceOrientation:self.interfaceOrientation]];
    
    //details View
    _detailsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (self.view.frame.size.height/2)) ];
    [_detailsView setBackgroundColor:[UIColor whiteColor]];
    [self initDetailsView];
    [self.view addSubview:_detailsView];
    
    // ****** Table View
    _indexTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _detailsView.frame.size.height, self.view.frame.size.width, (self.view.frame.size.height/2)-54) style:UITableViewStylePlain];
    [_indexTableView registerClass:[DetailsTableViewCell class] forCellReuseIdentifier:@"DetailsCell"];
    _indexTableView.dataSource= self;
    _indexTableView.delegate=self;
    [_indexTableView setEditing:YES];
    //_indexTableView.backgroundColor= [UIColor blueColor];
    
    [self.view addSubview:_indexTableView];
    
    // ****** BAKER BACKGROUND
    backgroundImageLandscape   = nil;
    backgroundImagePortrait    = nil;

    NSString *backgroundPathLandscape = self.book.bakerBackgroundImageLandscape;
    if (backgroundPathLandscape != nil) {
        backgroundPathLandscape  = [self.book.path stringByAppendingPathComponent:backgroundPathLandscape];
        backgroundImageLandscape = [UIImage imageWithContentsOfFile:backgroundPathLandscape];
    }

    NSString *backgroundPathPortrait = self.book.bakerBackgroundImagePortrait;
    if (backgroundPathPortrait != nil) {
        backgroundPathPortrait  = [self.book.path stringByAppendingPathComponent:backgroundPathPortrait];
        backgroundImagePortrait = [UIImage imageWithContentsOfFile:backgroundPathPortrait];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    if (!currentPageWillAppearUnderModal) {

        [super viewWillAppear:animated];
        [self.navigationController.navigationBar setTranslucent:NO];

        // Prevent duplicate observers
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"notification_touch_intercepted" object:nil];

        // ****** LISTENER FOR INTERCEPTOR WINDOW NOTIFICATION
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterceptedTouch:) name:@"notification_touch_intercepted" object:nil];

        // ****** LISTENER FOR CLOSING APPLICATION
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive:) name:@"applicationWillResignActiveNotification" object:nil];

    } else {

        // In case the orientation changed while being in modal view, restore the
        // webview and stuff to the current orientation
        [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
        [self didRotateFromInterfaceOrientation:self.interfaceOrientation];
    }
}
- (void)handleApplicationWillResignActive:(NSNotification *)notification {
    NSLog(@"[BakerView] Resign, saving...");
    [self saveBookStatusWithScrollIndex];
    adjustViewsOnAppDidBecomeActive = YES;
}
- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self startReading];

//    if (!currentPageWillAppearUnderModal) {
//
//
//
//        if (![self forceOrientationUpdate]) {
//            [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
//            //[self performSelector:@selector(hideBars:) withObject:@YES afterDelay:0.5];
//
//            // Condition to make sure we only call startReading the first time this callback is invoked
//            // Fixes page reload on coming back from fullscreen video (#611)
//            if (self.currPage == nil) {
//                
//            }
//
//            [self didRotateFromInterfaceOrientation:self.interfaceOrientation];
//        }
//    }

//    currentPageWillAppearUnderModal = NO;
}

- (void)viewDidLayoutSubviews {
    // UINavigationController likes to mess with subviews when app becomes active
    // viewDidLayoutSubviews is called after UINavigationController is already done,
    // so we can adjust the views
    //if (adjustViewsOnAppDidBecomeActive) {
       // NSLog(@"[BakerView] Adjusting views on appDidBecomeActive");
       // [self adjustScrollViewPosition];
       // if (indexViewController != nil) {
       //     [indexViewController adjustIndexView];
       // }
        //adjustViewsOnAppDidBecomeActive = NO;
    //}
}

- (BOOL)loadBookWithBookPath:(NSString *)bookPath {
    NSLog(@"[BakerView] Loading book from path: %@", bookPath);

    // ****** CLEANUP PREVIOUS BOOK
    [self cleanupBookEnvironment];

    // ****** LOAD CONTENTS
    //[self buildPageArray];

    // ****** SET STARTING PAGE


    // ****** SET SCREENSHOTS FOLDER
    NSString *screenshotFolder = self.book.bakerPageScreenshots;
    if (screenshotFolder) {
        // When a screenshots folder is specified in book.json
        cachedScreenshotsPath = [bookPath stringByAppendingPathComponent:screenshotFolder];
    }

    if (!screenshotFolder || ![[NSFileManager defaultManager] fileExistsAtPath:cachedScreenshotsPath]) {
        // When a screenshot folder is not specified in book.json, or is specified but not actually existing
        cachedScreenshotsPath = defaultScreeshotsPath;
    }
    NSLog(@"[BakerView] Screenshots stored at: %@", cachedScreenshotsPath);


    return YES;
}
- (void)cleanupBookEnvironment {

    //[self resetPageSlots];
    //[self resetPageDetails];

    [pages removeAllObjects];
    [toLoad removeAllObjects];
}

- (void)resetPageDetails {
    //NSLog(@"[BakerView] Reset page details array and empty screenshot directory");

    for (NSMutableDictionary *details in pageDetails) {
        for (NSString *key in details) {
            UIView *value = details[key];
            [value removeFromSuperview];
        }
    }

    [pageDetails removeAllObjects];
}
- (void)startReading {

    //[self setPageSize:[self getCurrentInterfaceOrientation:self.interfaceOrientation]];
    //[self buildPageDetails];
    //[self updateBookLayout];

    // ****** INDEX WEBVIEW INIT
    // we move it here to make it more clear and clean

    //if (indexViewController != nil) {
        // first of all, we need to clean the indexview if it exists.
      //  [indexViewController.view removeFromSuperview];
    //}
    //indexViewController = [[BKRIndexViewController alloc] initWithBook:self.book fileName:INDEX_FILE_NAME webViewDelegate:self];
    
    //if (detailsViewController != nil ) {
        //[detailsViewController.view removeFromSuperview];
    //}
    
    //detailsViewController = [[BookDetailsViewController alloc] initWithBook:self.book fileName:INDEX_FILE_NAME tableViewDelegate:self];
    //[self.navigationController.view addSubview:detailsViewController.view];
    //[self.view sendSubviewToBack:detailsViewController];
    //[detailsViewController loadContent];
    
    //[self.view addSubview:indexViewController.view];
    //[indexViewController loadContent];

    //currentPageIsDelayingLoading = YES;

//    [self addPageLoading:0];
//
//    if ([self.book.bakerRendering isEqualToString:@"three-cards"]) {
//        if (self.currentPageNumber != totalPages) {
//            [self addPageLoading:+1];
//        }
//
//        if (self.currentPageNumber != 1) {
//            [self addPageLoading:-1];
//        }
//    }

    //[self handlePageLoading];
}

- (void)setImageFor:(UIImageView *)view {
    if (pageWidth > pageHeight && backgroundImageLandscape != NULL) {
        // Landscape
        view.image = backgroundImageLandscape;
    } else if (pageWidth < pageHeight && backgroundImagePortrait != NULL) {
        // Portrait
        view.image = backgroundImagePortrait;
    } else {
        view.image = NULL;
    }
}

- (void)adjustScrollViewPosition {
    int scrollViewY = 0;
    //[UIView animateWithDuration:UINavigationControllerHideShowBarDuration
      //               animations:^{ self.scrollView.frame = CGRectMake(0, scrollViewY, pageWidth, pageHeight); }
        //             completion:nil];
}

- (void)setPageSize:(NSString*)orientation {
    NSLog(@"[BakerView] Set size for orientation: %@", orientation);

    pageWidth  = [[UIScreen mainScreen] bkrWidthForOrientationName:orientation];
    pageHeight = [[UIScreen mainScreen] bkrHeightForOrientationName:orientation];

    //[self setTappableAreaSizeForOrientation:orientation];

    //self.scrollView.contentSize = CGSizeMake(pageWidth * totalPages, pageHeight);
}

#pragma mark - BARS VISIBILITY
- (CGRect)getNewNavigationFrame:(BOOL)hidden {
    UINavigationBar *navigationBar = self.navigationController.navigationBar;

    int navX = navigationBar.frame.origin.x;
    int navW = navigationBar.frame.size.width;
    int navH = navigationBar.frame.size.height;

    if (hidden) {
        return CGRectMake(navX, -44, navW, navH);
    } else {
        return CGRectMake(navX, 20, navW, navH);
    }
}
- (BOOL)prefersStatusBarHidden {
    return self.barsHidden;
}
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}
- (void)toggleBars {
    // if modal view is up, don't toggle.
    if (!self.presentedViewController) {
        NSLog(@"[BakerView] Toggle bars visibility");

        if (self.barsHidden) {
            [self showBars];
        } else {
            [self hideBars:@YES];
        }
    }
}
- (void)showBars {

    self.barsHidden = NO;

    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}
- (void)showNavigationBar {

    CGRect newNavigationFrame = [self getNewNavigationFrame:NO];
    UINavigationBar *navigationBar = self.navigationController.navigationBar;

    navigationBar.frame = CGRectMake(newNavigationFrame.origin.x, -24, newNavigationFrame.size.width, newNavigationFrame.size.height);
    navigationBar.hidden = NO;

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         navigationBar.frame = newNavigationFrame;
                     }
                     completion:nil];
}
- (void)hideBars:(NSNumber *)animated {

    self.barsHidden = YES;

    BOOL animateHiding = [animated boolValue];

    if (animateHiding) {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    } else {
       [self setNeedsStatusBarAppearanceUpdate];
    }

    [self.navigationController setNavigationBarHidden:YES animated:animateHiding];
}
- (void)handleBookProtocol:(NSURL *)url
{
    // ****** Handle: book://
    NSLog(@"[BakerView]     Page is a link with scheme book:// --> download new book");
    if ([[url pathExtension] isEqualToString:@"html"]) {
        // page   --> [[url lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
        // anchor --> [url fragment];

        url = [url URLByDeletingLastPathComponent];
    }
    NSString *bookName = [[url lastPathComponent] stringByReplacingOccurrencesOfString:@".hpub" withString:@""];
    NSDictionary *userInfo = @{@"ID": bookName};

    [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_book_protocol" object:nil userInfo:userInfo];
}

#pragma mark - ORIENTATION
- (NSString *)getCurrentInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([self.book.orientation isEqualToString:@"portrait"] || [self.book.orientation isEqualToString:@"landscape"]) {
        return self.book.orientation;
    } else {
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            return @"landscape";
        } else {
            return @"portrait";
        }
    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    BOOL appOrientation = [supportedOrientation indexOfObject:[BKRUtils stringFromInterfaceOrientation:interfaceOrientation]] != NSNotFound;

    if ([self.book.orientation isEqualToString:@"portrait"]) {
        return appOrientation && UIInterfaceOrientationIsPortrait(interfaceOrientation);
    } else if ([self.book.orientation isEqualToString:@"landscape"]) {
        return appOrientation && UIInterfaceOrientationIsLandscape(interfaceOrientation);
    } else {
        return appOrientation;
    }
}
- (BOOL)shouldAutorotate {
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations {
    if ([self.book.orientation isEqualToString:@"portrait"]) {
        return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
    } else if ([self.book.orientation isEqualToString:@"landscape"]) {
        return UIInterfaceOrientationMaskLandscape;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Notify the index view
    //[indexViewController willRotate];

    // Notify the current loaded views
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //[indexViewController rotateFromOrientation:fromInterfaceOrientation toOrientation:self.interfaceOrientation];
    //[self setCurrentPageHeight];
}

- (BOOL)forceOrientationUpdate {
    // We need to run this only once to prevent looping in -viewWillAppear
    if (shouldForceOrientationUpdate) {
        shouldForceOrientationUpdate = NO;
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

        if ( (UIInterfaceOrientationIsLandscape(interfaceOrientation) && [self.book.orientation isEqualToString:@"landscape"])
            ||
            (UIInterfaceOrientationIsPortrait(interfaceOrientation) && [self.book.orientation isEqualToString:@"portrait"]) ) {

            //NSLog(@"[BakerView] Device and book orientations are in sync");
            return NO;
        } else {
            //NSLog(@"[BakerView] Device and book orientations are out of sync, force orientation update");

            // Present and dismiss a vanilla view controller to trigger the orientation update
            [self presentViewController:[UIViewController new] animated:NO completion:^{
                dispatch_after(0, dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:NO completion:nil];
                });
            }];
            return YES;
        }

    } else {
        return NO;
    }
}

#pragma Mark - DETAILS
-(void)initDetailsView{
    labelhpub = [[UILabel alloc] initWithFrame:CGRectMake(0, 0 , self.view.frame.size.width, 30)];
    labelhpub.text=[[self.book.bookData objectForKey:@"hpub"] stringValue];
    [_detailsView addSubview:labelhpub];
    labeltitle.text=[self.book.bookData objectForKey:@"title"];
    labeldate.text=[self.book.bookData objectForKey:@"date"];
   labelauthor.text=[self.book.bookData objectForKey:@"author"];
    labelcreators.text=[self.book.bookData objectForKey:@"creator"];
    labelcategories.text=[self.book.bookData objectForKey:@"categories"];
    labelpublisher.text=[self.book.bookData objectForKey:@"publisher"];
    labelurl.text=[self.book.bookData objectForKey:@"url"];
    labelcover.text=[self.book.bookData objectForKey:@"cover"];
    labelorientation.text=[self.book.bookData objectForKey:@"orientations"];
    labelID.text=[self.book.bookData objectForKey:@"ID"];

}

#pragma mark - MEMORY
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSArray *viewControllers = self.navigationController.viewControllers;
    if ([viewControllers indexOfObject:self] == NSNotFound) {
        // Baker book is disappearing because it was popped from the navigation stack -> Baker book is closing
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BakerIssueClose" object:self]; // -> Baker Analytics Event
        //[self saveBookStatusWithScrollIndex];
    }
}
- (void)saveBookStatusWithScrollIndex {
    //[bookStatus save];
    //NSLog(@"[BakerView] Saved status");
}
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}
- (void)dealloc {
    
    // Set web views delegates to nil, mandatory before releasing UIWebview instances
    //self.currPage.delegate = nil;
    //nextPage.delegate = nil;
    //prevPage.delegate = nil;

}

#pragma mark - MF MAIL COMPOSER
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {

    // Log the result for debugging purpose
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"[BakerView]     Mail cancelled.");
            break;

        case MFMailComposeResultSaved:
            NSLog(@"[BakerView]     Mail saved.");
            break;

        case MFMailComposeResultSent:
            NSLog(@"[BakerView]     Mail sent.");
            break;

        case MFMailComposeResultFailed:
            NSLog(@"[BakerView]     Mail failed, check NSError.");
            break;

        default:
            NSLog(@"[BakerView]     Mail not sent.");
            break;
    }

    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    //NSLog(@"%lu",(unsigned long)self.book.contents.count);
    return self.book.contents.count;
}
-(DetailsTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailsCell" forIndexPath:indexPath];
    //NSLog(@"%@", indexPath);
    if (cell == nil) {
        cell = [[DetailsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DetailsCell"];
    }
    
    cell.contentName.text= [self.book.contents objectAtIndex:indexPath.row];
    return cell;
}
-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}
-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
    
}

#pragma mark - TableviewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

@end
