//
//  BookDetailsViewController.m
//  SlidyxEditor
//
//  Created by Eduardo on 7/7/15.
//  Copyright (c) 2015 Eduardo. All rights reserved.
//

#import "BookDetailsViewController.h"
#import "BKRBookViewController.h"
#import "DetailsTableViewCell.h"

#import "UIScreen+BakerExtensions.h"

@interface BookDetailsViewController ()

@end

@implementation BookDetailsViewController

-(id)initWithBook:(BKRBook*)bakerBook fileName:(NSString*)name tableViewDelegate:(UIViewController<UITableViewDelegate>*)delegate {
    self = [super init];
    if (self) {
        
        _book = bakerBook;
        
        fileName        = name;

        
        disabled    = NO;
        indexWidth  = 0;
        indexHeight = 0;
        
        //[self setPageSizeForOrientation:[UIApplication sharedApplication].statusBarOrientation];
        
    }
    return self;
}
-(void)loadView{
    NSLog(@"loading tableview ...");
    UITableView *tableview = [[UITableView alloc] init];
    
    tableview.dataSource = self;
    tableview.delegate=self;
    [tableview registerClass:[DetailsTableViewCell class] forCellReuseIdentifier:@"DetailsCell"];
    
    self.view = tableview;
    [self loadContent];
    
    NSLog(@"%lUI", (unsigned long)self.book.contents.count);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)loadContent{
    NSString* path = self.indexPath;
    
//    UIWebView *webView = (UIWebView*)self.view;
//    webView.mediaPlaybackRequiresUserAction = ![self.book.bakerMediaAutoplay boolValue];
//    [self setBounceForWebView:webView bounces:[self.book.bakerIndexBounce boolValue]];
//    
//    //NSLog(@"[IndexView] Path to index view is %@", path);
//    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
//        disabled = NO;
//        [(UIWebView *)self.view loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
//    } else {
//        NSLog(@"[IndexView] Index HTML not found at %@", path);
//        disabled = YES;
//    }
}
- (void)setPageSizeForOrientation:(UIInterfaceOrientation)orientation{
    pageWidth  = [[UIScreen mainScreen] bkrWidthForOrientation:orientation];
    pageHeight = [[UIScreen mainScreen] bkrHeightForOrientation:orientation];
    NSLog(@"[IndexView] Set IndexView size to %dx%d", pageWidth, pageHeight);
}
- (BOOL)isDisabled{
    return disabled;
}
- (void)willRotate{
    //[self fadeOut];
}
- (void)rotateFromOrientation:(UIInterfaceOrientation)fromInterfaceOrientation toOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    [self setPageSizeForOrientation:toInterfaceOrientation];
    [self setActualSize];
    //[self setIndexViewHidden:hidden withAnimation:NO];
    //[self fadeIn];
}
- (void)setActualSize{
    actualIndexWidth  = MIN(indexWidth, pageWidth);
    actualIndexHeight = MIN(indexHeight, pageHeight);
}
- (void)adjustIndexView{
    [self setPageSizeForOrientation:[UIApplication sharedApplication].statusBarOrientation];
    [self setActualSize];
    //[self setIndexViewHidden:self.isIndexViewHidden withAnimation:NO];
}
- (void)setViewFrame:(CGRect)frame{
    self.view.frame = frame;
    indexScrollView.contentSize = cachedContentSize;
}
- (NSString*)indexPath{
    return [self.book.path stringByAppendingPathComponent:fileName];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - table view data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}
-(DetailsTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailsCell" forIndexPath:indexPath];
    cell.contentName.text=@"test Content";
    return cell;
}

@end
