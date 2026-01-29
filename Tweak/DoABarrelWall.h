/*
	initially, I thought that the inclusion of headers was pointless,
	as it just replaces the import line with the contents of the header, or at least that's how I think it works
	(https://stackoverflow.com/questions/439662/what-is-the-difference-between-import-and-include-in-objective-c)
	While it may seem to be a preference thing, I now prefer to use headers as a means to organize global variables later used in the Tweak.xm file
*/

#import <UIKit/UIKit.h>
#import <GcUniversal/GcImagePickerUtils.h>
#import <GcUniversal/GcImageUtils.h>
#import <Cephei/HBPreferences.h>

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

HBPreferences* preferences;

BOOL lockscreenEnabled;
BOOL homescreenEnabled;
BOOL compatibilityModeEnabled;
BOOL fadeEnabled;

UIColor *lockAvgColor;
NSCache *cacheImageList;

NSString * const kPrefsIdentifier = @"com.denial.doabarrelwallprefs";
