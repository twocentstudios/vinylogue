//
//  TCSVinylogueDesign.h
//  vinylogue
//
//  Created by Christopher Trott on 2/20/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#ifndef vinylogue_TCSVinylogueDesign_h
#define vinylogue_TCSVinylogueDesign_h

// Color picking helpers
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]
#define GRAYCOLOR(g) [UIColor colorWithRed:(g)/255.0f green:(g)/255.0f blue:(g)/255.0f alpha:1]
#define GRAYACOLOR(g,a) [UIColor colorWithRed:(g)/255.0f green:(g)/255.0f blue:(g)/255.0f alpha:(a)]
#define COLORA(c,a) [c colorWithAlphaComponent:a]

// Application Constant Colors
#define CLEAR GRAYACOLOR(255, 0)
#define BLACK GRAYCOLOR(0)
#define WHITE GRAYCOLOR(255)
#define BLACKA(a) GRAYACOLOR(0, a)
#define WHITEA(a) GRAYACOLOR(255, a)

#define WHITE_SUBTLE GRAYCOLOR(240)
#define BLUE_DARK RGBCOLOR(15, 24, 46)
#define BLUE_BOLD RGBCOLOR(67, 85, 129)
#define BLUE_PERI GRAYCOLOR(220)
#define BLUE_PERI_SHADOW GRAYCOLOR(195)

#define BAR_BUTTON_TINT GRAYCOLOR(220);

// Application Fonts
#define FONT_AVN_ULTRALIGHT(s) [UIFont fontWithName:@"AvenirNext-UltraLight" size:(s)]
#define FONT_AVN_DEMIBOLD(s) [UIFont fontWithName:@"AvenirNext-DemiBold" size:(s)]
#define FONT_AVN_MEDIUM(s) [UIFont fontWithName:@"AvenirNext-Medium" size:(s)]
#define FONT_AVN_REGULAR(s) [UIFont fontWithName:@"AvenirNext-Regular" size:(s)]

// Shadow Helpers
#define SHADOW_TOP CGSizeMake(0, -0.5)
#define SHADOW_BOTTOM CGSizeMake(0, 0.5)

#endif
