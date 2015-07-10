//
//  BookDetailsViewController.h
//  SlidyxEditor
//
//  Created by Eduardo on 7/7/15.
//  Copyright (c) 2015 Eduardo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BKRBook.h"

@interface BookDetailsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>{
        
        NSString *fileName;
        UIScrollView *indexScrollView;
        UIViewController <UITableViewDelegate> *tableViewDelegate;
        UIViewController <UITableViewDataSource> *tableViewDatasource;
        UICollectionViewCell *ColectionCell;
    
        int pageY;
        int pageWidth;
        int pageHeight;
        int indexWidth;
        int indexHeight;
        int actualIndexWidth;
        int actualIndexHeight;
        
        BOOL disabled;
        BOOL loadedFromBundle;
        
        CGSize cachedContentSize;
    }
    
    @property (nonatomic, strong) BKRBook *book;
- (id)initWithBook:(BKRBook*)bakerBook fileName:(NSString*)name tableViewDelegate:(UIViewController<UITableViewDelegate>*)delegate;
- (void)loadContent;
- (void)setPageSizeForOrientation:(UIInterfaceOrientation)orientation;
- (BOOL)isDisabled;
- (void)willRotate;
- (void)rotateFromOrientation:(UIInterfaceOrientation)fromInterfaceOrientation toOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
//- (void)fadeOut;
//- (void)fadeIn;
//- (BOOL)stickToLeft;
//- (CGSize)sizeFromContentOf:(UIWebView*)webView;
- (void)setActualSize;
- (void)adjustIndexView;
- (void)setViewFrame:(CGRect)frame;
- (NSString*)indexPath;

@end
