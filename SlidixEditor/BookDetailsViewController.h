//
//  BookDetailsViewController.h
//  SlidyxEditor
//
//  Created by Eduardo on 7/7/15.
//  Copyright (c) 2015 Eduardo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BKRBook.h"

@interface BookDetailsViewController : UIViewController<UITableViewDataSource>{
        
        NSString *fileName;
        UIScrollView *indexScrollView;
        UIViewController <UITableViewDelegate> *collectionViewDelegate;
        UIViewController <UITableViewDataSource> *collectionViewDatasource;
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



@end
