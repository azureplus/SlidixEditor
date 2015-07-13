//
//  DetailsTableViewCell.m
//  SlidyxEditor
//
//  Created by Eduardo on 7/10/15.
//  Copyright (c) 2015 Eduardo. All rights reserved.
//

#import "DetailsTableViewCell.h"

@implementation DetailsTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
            reuseID = reuseIdentifier;
            
             _contentName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height)];
            [_contentName setTextColor:[UIColor blackColor]];
            [_contentName setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0f]];
            [_contentName setTranslatesAutoresizingMaskIntoConstraints:NO];
            //self.contentView.backgroundColor=[UIColor greenColor];
            [self.contentView addSubview:_contentName];
        

            
        
    }
    return self;
}
- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
