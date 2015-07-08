//
//  BookDetailsViewController.m
//  SlidyxEditor
//
//  Created by Eduardo on 7/7/15.
//  Copyright (c) 2015 Eduardo. All rights reserved.
//

#import "BookDetailsViewController.h"

@interface BookDetailsViewController ()

@end

@implementation BookDetailsViewController
- (id)initWithBook:(BKRBook*)bakerBook fileName:(NSString*)name webViewDelegate:(UIViewController<UICollectionViewDelegate>*)delegate {
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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - CollectionViewDatasource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)sectioncollectionView{
    return 0;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [[UICollectionViewCell alloc] init];
    return cell;
}

@end
