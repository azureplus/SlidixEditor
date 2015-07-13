//
//  DetailsTableViewCell.h
//  SlidyxEditor
//
//  Created by Eduardo on 7/10/15.
//  Copyright (c) 2015 Eduardo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailsTableViewCell : UITableViewCell
{
    NSString *reuseID;
}

@property(strong, nonatomic) UILabel *contentName;

@end
