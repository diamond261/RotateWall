#import "DBWRootListController.h"
#import <PhotosUI/PhotosUI.h>
#import <rootless.h>
#import <Cephei/HBPreferences.h>
#import <Cephei/HBRespringController.h>
#import <Preferences/PSSpecifier.h>
#import <spawn.h>
#import <unistd.h>

static NSString * const kPrefsIdentifier = @"com.denial.doabarrelwallprefs";
static NSString * const kRotateWallDir = @"/var/mobile/Library/RotateWall";

static NSString * const kLockPortraitKey = @"lockPortraitPath";
static NSString * const kLockLandscapeKey = @"lockLandscapePath";
static NSString * const kHomePortraitKey = @"homePortraitPath";
static NSString * const kHomeLandscapeKey = @"homeLandscapePath";

static NSString * const kLockPortraitFilename = @"lock-portrait.jpg";
static NSString * const kLockLandscapeFilename = @"lock-landscape.jpg";
static NSString * const kHomePortraitFilename = @"home-portrait.jpg";
static NSString * const kHomeLandscapeFilename = @"home-landscape.jpg";

@interface DBWRootListController () <PHPickerViewControllerDelegate>

@property (nonatomic, strong) HBPreferences *prefs;
@property (nonatomic, copy) NSString *pendingPrefsKey;
@property (nonatomic, copy) NSString *pendingFilename;

@end

@implementation DBWRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

- (instancetype)init {
	if (!(self = [super init])) {
		return self;
	}

	_prefs = [[HBPreferences alloc] initWithIdentifier:kPrefsIdentifier];
	return self;
}

- (void)pickPhoto:(PSSpecifier *)specifier {
	NSString *prefsKey = [specifier propertyForKey:@"rwPrefsKey"];
	NSString *filename = [specifier propertyForKey:@"rwFilename"];
	[self presentPickerForKey:prefsKey filename:filename];
}

- (void)presentPickerForKey:(NSString *)prefsKey filename:(NSString *)filename {
	if (@available(iOS 14.0, *)) {
		PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
		config.selectionLimit = 1;
		config.filter = [PHPickerFilter imagesFilter];

		PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
		picker.delegate = self;

		self.pendingPrefsKey = prefsKey;
		self.pendingFilename = filename;
		[self presentViewController:picker animated:YES completion:nil];
	}
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results  API_AVAILABLE(ios(14.0)) {
	[picker dismissViewControllerAnimated:YES completion:nil];

	PHPickerResult *result = [results firstObject];
	if (!result) {
		return;
	}

	NSItemProvider *provider = result.itemProvider;
	if (![provider canLoadObjectOfClass:[UIImage class]]) {
		return;
	}

	__weak __typeof(self) weakSelf = self;
	[provider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading> object, NSError *error) {
		if (error || ![object isKindOfClass:[UIImage class]]) {
			return;
		}

		UIImage *image = (UIImage *)object;
		dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf saveImage:image];
		});
	}];
}

- (void)saveImage:(UIImage *)image {
	if (!image || !self.pendingPrefsKey || !self.pendingFilename) {
		return;
	}

	NSString *directory = ROOT_PATH_NS(kRotateWallDir);
	NSString *destination = [directory stringByAppendingPathComponent:self.pendingFilename];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];

	NSData *jpegData = UIImageJPEGRepresentation(image, 0.92);
	if (![jpegData writeToFile:destination atomically:YES]) {
		return;
	}

	[self.prefs setObject:destination forKey:self.pendingPrefsKey];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.denial.doabarrelwallprefs/ReloadPrefs"), NULL, NULL, 0);
}

- (void)respringUtil {
	if ([HBRespringController respondsToSelector:@selector(respring)]) {
		[HBRespringController respring];
		return;
	}

	NSArray<NSString *> *sbreloadPaths = @[ROOT_PATH_NS(@"/usr/bin/sbreload"), @"/usr/bin/sbreload"];
	for (NSString *path in sbreloadPaths) {
		if ([[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
			pid_t pid;
			char *argv[] = { (char *)[path UTF8String], NULL };
			extern char **environ;
			if (posix_spawn(&pid, [path UTF8String], NULL, NULL, argv, environ) == 0) {
				return;
			}
		}
	}

	NSArray<NSString *> *ldrestartPaths = @[ROOT_PATH_NS(@"/usr/bin/ldrestart"), @"/usr/bin/ldrestart"];
	for (NSString *path in ldrestartPaths) {
		if ([[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
			pid_t pid;
			char *argv[] = { (char *)[path UTF8String], NULL };
			extern char **environ;
			if (posix_spawn(&pid, [path UTF8String], NULL, NULL, argv, environ) == 0) {
				return;
			}
		}
	}

	NSArray<NSString *> *killallPaths = @[ROOT_PATH_NS(@"/usr/bin/killall"), @"/usr/bin/killall"];
	for (NSString *path in killallPaths) {
		if ([[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
			pid_t pid;
			char *argv[] = { (char *)[path UTF8String], "-9", "SpringBoard", NULL };
			extern char **environ;
			if (posix_spawn(&pid, [path UTF8String], NULL, NULL, argv, environ) == 0) {
				return;
			}
		}
	}

	[HBRespringController respringAndReturnTo:[NSURL URLWithString:@"prefs:root=RotateWall"]];
}

- (void)respringUtil:(id)specifier {
	[self respringUtil];
}

@end
