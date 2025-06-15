//
//  TCSSettingsCells.h
//  vinylogue
//
//  Created by Christopher Trott on 2/21/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TCSSimpleTableDataSource.h"

@interface TCSSettingsCell : UITableViewCell <TCSSimpleCell>

@end

@interface TCSBigSettingsCell : TCSSettingsCell

@end

@interface TCSSettingsHeaderCell : UITableViewCell <TCSSimpleCell>

@end

@interface TCSSettingsFooterCell : UITableViewCell <TCSSimpleCell>

@end