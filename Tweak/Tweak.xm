#import "DoABarrelWall.h"

@interface SBLockScreenManager
+ (id)sharedInstance;
- (void)wallpaperDidChangeForVariant:(NSInteger)arg0 ;
@end

@interface SBFWallpaperView : UIView
@property (assign,nonatomic) BOOL parallaxEnabled;
@property (retain, nonatomic) UIView *contentView;
@end

@interface SBWallpaperViewController : UIViewController //SBWWallpaperViewController on iOS 15, as there is a new framework (SpringBoardWallpaper.framework), same thing though
@property (retain, nonatomic) SBFWallpaperView *lockscreenWallpaperView;
@property (retain, nonatomic) SBFWallpaperView *homescreenWallpaperView;
-(NSHashTable *)_observersForVariant:(NSInteger)arg0 ;
-(id)_blurViewsForVariant:(NSInteger)arg0 ;
@end

//https://headers.cynder.me/index.php?sdk=ios/15.4&fw=PrivateFrameworks/SpringBoard.framework&file=Headers/SBWallpaperController.h
@interface SBWallpaperController : NSObject {
	SBWallpaperViewController *_wallpaperViewController; //iOS 14+
}
+ (id)sharedInstance;

//iOS 13-
@property (retain, nonatomic) SBFWallpaperView *lockscreenWallpaperView;
@property (retain, nonatomic) SBFWallpaperView *homescreenWallpaperView;
-(NSHashTable *)_observersForVariant:(NSInteger)arg0 ;
-(id)_blurViewsForVariant:(NSInteger)arg0 ;
@end

@interface UIDeviceRGBColor : UIColor
@end

@interface _SBWFakeBlurView : UIView
@property (readonly, nonatomic) NSInteger variant;
-(NSInteger)effectiveStyle;
@end

@interface _SBFakeBlurView : _SBWFakeBlurView
@end

@interface CSCoverSheetView : UIView
@property (readonly, nonatomic) UIView *slideableContentView;
@end

//big thanks to gc giving the best suggestion to optimize my tweak before release by caching images

//this group is for setting the wallpapers using the system interface
%group systemWallpaper

	//enum for the wallpaper destination
	typedef NS_OPTIONS(NSInteger, WallpaperLocation) {
		kLockScreen = 1 << 0,
		kHomeScreen = 1 << 1
	};

	static NSString * const kLockPortraitKey = @"lockPortraitPath";
	static NSString * const kLockLandscapeKey = @"lockLandscapePath";
	static NSString * const kHomePortraitKey = @"homePortraitPath";
	static NSString * const kHomeLandscapeKey = @"homeLandscapePath";

	static BOOL lastKnownLandscape = NO;
	static BOOL lastAppliedLandscape = NO;
	static BOOL hasAppliedOnce = NO;

	static BOOL currentLandscapeOrientation(void) {
		BOOL isLandscape = lastKnownLandscape;
		UIInterfaceOrientation interfaceOrientation = UIInterfaceOrientationUnknown;
		if (@available(iOS 13.0, *)) {
			for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
				if (scene.activationState != UISceneActivationStateForegroundActive) {
					continue;
				}

				if ([scene isKindOfClass:[UIWindowScene class]]) {
					interfaceOrientation = ((UIWindowScene *)scene).interfaceOrientation;
					break;
				}
			}
		}

		if (interfaceOrientation != UIInterfaceOrientationUnknown) {
			isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
		} else {
			UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
			if (UIDeviceOrientationIsLandscape(deviceOrientation)) {
				isLandscape = YES;
			} else if (UIDeviceOrientationIsPortrait(deviceOrientation)) {
				isLandscape = NO;
			}
		}

		lastKnownLandscape = isLandscape;
		return isLandscape;
	}

	static NSString *validatedPath(NSString *path) {
		if (![path isKindOfClass:[NSString class]] || [path length] == 0) {
			return nil;
		}

		if (![path hasPrefix:@"/"]) {
			return nil;
		}

		BOOL isDirectory = NO;
		if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] || isDirectory) {
			return nil;
		}

		return path;
	}

	static NSString *pathForKey(NSString *key) {
		if ([key isEqualToString:kLockPortraitKey]) return validatedPath(lockPortraitPath);
		if ([key isEqualToString:kLockLandscapeKey]) return validatedPath(lockLandscapePath);
		if ([key isEqualToString:kHomePortraitKey]) return validatedPath(homePortraitPath);
		if ([key isEqualToString:kHomeLandscapeKey]) return validatedPath(homeLandscapePath);
		return nil;
	}

	static UIImage *wallpaperImageForKey(NSString *key) {
		NSString *path = pathForKey(key);
		if (!path || [path length] == 0) {
			return nil;
		}

		UIImage *img = [cacheImageList objectForKey:path];
		if (!img) {
			img = [UIImage imageWithContentsOfFile:path];
			if (!img) {
				return nil;
			}
			[cacheImageList setObject:img forKey:path];
		}
		return img;
	}

	static UIImage *wallpaperImageForLocation(WallpaperLocation location) {
		BOOL landscape = currentLandscapeOrientation();
		NSString *key = (location & kLockScreen)
			? (landscape ? kLockLandscapeKey : kLockPortraitKey)
			: (landscape ? kHomeLandscapeKey : kHomePortraitKey);
		return wallpaperImageForKey(key);
	}

	static void setImageForImageView(UIImageView *imageView, UIImage *image) {
		if (!imageView || !image) {
			return;
		}

		[imageView setBounds:[UIScreen mainScreen].bounds];
		[imageView setContentMode:UIViewContentModeScaleAspectFill];

		if (fadeEnabled) {
			[UIView transitionWithView:imageView duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
				imageView.image = image;
			} completion:nil];
		} else {
			[imageView setImage:image];
		}
	}

	static UIColor *averageColorForImage(UIImage *image) {
		if (!image || !image.CGImage) {
			return nil;
		}

		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		unsigned char rgba[4] = {0, 0, 0, 0};
		CGContextRef ctx = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
		if (!ctx) {
			CGColorSpaceRelease(colorSpace);
			return nil;
		}

		CGContextDrawImage(ctx, CGRectMake(0, 0, 1, 1), image.CGImage);
		CGContextRelease(ctx);
		CGColorSpaceRelease(colorSpace);

		CGFloat r = rgba[0] / 255.0;
		CGFloat g = rgba[1] / 255.0;
		CGFloat b = rgba[2] / 255.0;
		CGFloat a = rgba[3] / 255.0;
		return [UIColor colorWithRed:r green:g blue:b alpha:a];
	}

	static void updateForImageLocation(UIImage *img, WallpaperLocation loc) {

		SBWallpaperController *wallpaperController = [objc_getClass("SBWallpaperController") sharedInstance];
		SBWallpaperViewController *responsible = SYSTEM_VERSION_LESS_THAN(@"14") ? wallpaperController : [wallpaperController valueForKey:@"_wallpaperViewController"];

		SBFWallpaperView *wallpaperView = (loc & kLockScreen) ? [responsible lockscreenWallpaperView] : [responsible homescreenWallpaperView];
		[wallpaperView setParallaxEnabled:NO];

		UIImageView *wpImageView = (UIImageView *)[wallpaperView contentView];
		if ([wpImageView isKindOfClass:[UIImageView class]]) {
			setImageForImageView(wpImageView, img);
		}

		NSHashTable *blurs = [responsible _blurViewsForVariant:loc-1];
		for (_SBWFakeBlurView *blur in blurs) {
			if ([blur isKindOfClass:objc_getClass("_SBFakeBlurView")] || [blur isKindOfClass:objc_getClass("_SBWFakeBlurView")]) {
				if ([blur effectiveStyle] == 0) {
					SBFWallpaperView *fakeWPView = (SBFWallpaperView *)[blur valueForKey:@"_wallpaperView"];
					[fakeWPView setParallaxEnabled:NO];
					[fakeWPView contentView].bounds = [UIScreen mainScreen].bounds;

					NSString *key = SYSTEM_VERSION_LESS_THAN(@"15") ? @"_imageView" : @"_providedImageView";

					UIImageView *fakeImageView = (UIImageView *)[blur valueForKey:key];
					setImageForImageView(fakeImageView, img);
				}
			}
		}

		if (compatibilityModeEnabled && loc & kLockScreen) {
			UIColor *avgColor = averageColorForImage(img);
			if (avgColor) {
				CGFloat r,g,b,a;
				[avgColor getRed:&r green:&g blue:&b alpha:&a];

				//UIDeviceRGBColor is needed as the SB uses it and it would otherwise crash
				lockAvgColor = [[objc_getClass("UIDeviceRGBColor") alloc] initWithRed:r green:g blue:b alpha:a];
			}
		}
	}

	static void updateWallpaperForLocation(WallpaperLocation location) {
		if (location & kLockScreen && !lockscreenEnabled) return;
		if (location & kHomeScreen && !homescreenEnabled) return;

		UIImage *newWallpaper = wallpaperImageForLocation(location);
		if (!newWallpaper) {
			return;
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			if (location & kLockScreen)
				updateForImageLocation(newWallpaper, kLockScreen);

			if (location & kHomeScreen)
				updateForImageLocation(newWallpaper, kHomeScreen);

			if (compatibilityModeEnabled) {
				NSInteger variant = (location & kLockScreen) ? 0 : 1;
				[[objc_getClass("SBLockScreenManager") sharedInstance] wallpaperDidChangeForVariant:variant];
				CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.apple.springboard.wallpaperchanged"), NULL, NULL, 0);
			}
		});
	}

	static void updateWallpapersForCurrentOrientation(void) {
		if (lockscreenEnabled) {
			updateWallpaperForLocation(kLockScreen);
		}
		if (homescreenEnabled) {
			updateWallpaperForLocation(kHomeScreen);
		}
	}

	static void handleOrientationChange(void) {
		BOOL landscape = currentLandscapeOrientation();
		if (hasAppliedOnce && landscape == lastAppliedLandscape) {
			return;
		}
		lastAppliedLandscape = landscape;
		hasAppliedOnce = YES;
		updateWallpapersForCurrentOrientation();
	}

	static void startOrientationMonitoring(void) {
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			handleOrientationChange();
		}];
		handleOrientationChange();
	}

	%hook SBLockScreenManager

		- (id)averageColorForCurrentWallpaper {

			return (compatibilityModeEnabled && lockAvgColor) ? lockAvgColor : %orig;

		}

	%end

	//make sure we have 2 WPImageViews, as that makes it easier to set the wallpapers
	%hook WPController

		- (BOOL)variantsShareWallpaper {

			return NO;

		}

	%end

	%hook SpringBoard
		- (void)applicationDidFinishLaunching:(id)application {
			%orig;
			startOrientationMonitoring();
		}
	%end

	//fuck iOS 15
	%hook _SBWFakeBlurView

		- (void)layoutSubviews {

			%orig;

			if ([self variant] == 0)
				[[self valueForKey:@"_providedImageView"] setFrame:[UIScreen mainScreen].bounds];

		}

	%end

	%hook CSCoverSheetView
		BOOL isLocked = NO;
		-(void)scrollViewDidEndScrolling:(id)arg0 {
			%orig;

			isLocked = NO;
			/*
				Reset the lock
				The lock is set, once the wallpaper has been set once, to avoid unnecessary updates, which happen quite often
			*/

		}
		-(void)scrollViewDidScroll:(id)arg0 withContext:(void *)arg1 {
			%orig;
			if (isLocked || !lockscreenEnabled)
				return;

			UIImage *newWallpaper = wallpaperImageForLocation(kLockScreen);
			if (!newWallpaper)
				return;

			/*
				Now this block is ugly AF, but I couldn't find a better way to do it
				(The goal is to overwrite the image which is displayed during transitioning to the lockscreen camera)
			*/
			for (UIView *subview in self.slideableContentView.subviews) {
				if ([subview isKindOfClass:objc_getClass("SBDashBoardWallpaperEffectView")]) {
					for (UIView *fakeBlur in subview.subviews) {
						if ([fakeBlur isKindOfClass:objc_getClass("_SBFakeBlurView")]) {
							UIImageView *imgView = (UIImageView *)[fakeBlur valueForKey:@"_imageView"];
							imgView.bounds = [UIScreen mainScreen].bounds;
							[imgView setContentMode:UIViewContentModeScaleAspectFill];
							[imgView setImage:newWallpaper];

							isLocked = YES;
							return; // break out of the loops is early for performance (not that it makes a difference lol)
						}
					}
				}
			}

		}
	%end

%end //end systemWallpaper section

//this constructor is run only ONCE at respring
%ctor {

	//retrieve preferences from /var/mobile/Library/Preferences/
	preferences = [[HBPreferences alloc] initWithIdentifier:kPrefsIdentifier];

	//get values from the list
	[preferences registerBool:&lockscreenEnabled default:NO forKey:@"lockscreenEnabled"];
	[preferences registerBool:&homescreenEnabled default:NO forKey:@"homescreenEnabled"];
	[preferences registerBool:&compatibilityModeEnabled default:YES forKey:@"compatibilityModeEnabled"]; //mainly Jellyfish atm
	[preferences registerBool:&fadeEnabled default:NO forKey:@"fadeEnabled"];
	[preferences registerObject:&lockPortraitPath default:nil forKey:@"lockPortraitPath"];
	[preferences registerObject:&lockLandscapePath default:nil forKey:@"lockLandscapePath"];
	[preferences registerObject:&homePortraitPath default:nil forKey:@"homePortraitPath"];
	[preferences registerObject:&homeLandscapePath default:nil forKey:@"homeLandscapePath"];

	cacheImageList = [[NSCache alloc] init];
	[cacheImageList setCountLimit:4];
	[cacheImageList setEvictsObjectsWithDiscardedContent:YES];

	[preferences registerPreferenceChangeBlock:^{
		[cacheImageList removeAllObjects];
		handleOrientationChange();
	}];

		//initialize system wallpaper section
		Class wpControllerClass = SYSTEM_VERSION_LESS_THAN(@"15") ? (SYSTEM_VERSION_LESS_THAN(@"14") ? objc_getClass("SBWallpaperController") : objc_getClass("SBWallpaperViewController")) : objc_getClass("SBWWallpaperViewController");
		%init(systemWallpaper, WPController = wpControllerClass);

}
