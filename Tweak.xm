#import <SpringBoard/SBAwayView.h>
#import <SpringBoard/SBAwayChargingView.h>
#import <SpringBoard/SBBatteryChargingView.h>

#define PATH @"/System/Library/CoreServices/SpringBoard.app"

static BOOL LSBattery = YES;
static BOOL LSReflection = YES;

static BOOL ABBattery = YES;
static BOOL ABReflection = YES;
static BOOL ABWallpaper = YES;

static BOOL ABAnimation = YES;
static BOOL ABFullStatus = YES;

static void ABSettings(){
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.poynterco.chargingbattery.plist"];
	LSBattery = [settings objectForKey:@"LSBattery"] ? [[settings objectForKey:@"LSBattery"] boolValue] : YES;
	LSReflection = [settings objectForKey:@"LSReflection"] ? [[settings objectForKey:@"LSReflection"] boolValue] : YES;
	ABBattery = [settings objectForKey:@"ABBattery"] ? [[settings objectForKey:@"ABBattery"] boolValue] : YES;
	ABReflection = [settings objectForKey:@"ABReflection"] ? [[settings objectForKey:@"ABReflection"] boolValue] : YES;
	ABWallpaper = [settings objectForKey:@"ABWallpaper"] ? [[settings objectForKey:@"ABWallpaper"] boolValue] : YES;
	ABAnimation = [settings objectForKey:@"ABAnimation"] ? [[settings objectForKey:@"ABAnimation"] boolValue] : YES;
	ABFullStatus = [settings objectForKey:@"ABFullStatus"] ? [[settings objectForKey:@"ABFullStatus"] boolValue] : YES;
}

%hook SBAwayView
-(void)showChargingView{
	%orig;
	ABSettings();     
	if (!ABAnimation)
		return;
	SBBatteryChargingView *chargingView = [[self chargingView] chargingView];
	UIImageView *chargingBattery = MSHookIvar <UIImageView *>(chargingView,"_topBatteryView");
	UIDeviceBatteryState batteryState = [UIDevice currentDevice].batteryState;
	if (batteryState == UIDeviceBatteryStateUnplugged){
		[chargingBattery stopAnimating];
		if (LSReflection) {
			[chargingView setShowsReflection:YES];
		} else {
			[chargingView setShowsReflection:NO];
		}
		return;
	} else {
		if ([chargingView _currentBatteryIndex] == 17){
			[chargingBattery stopAnimating];
			%orig;
			return;
		} else {
			if (batteryState == UIDeviceBatteryStateCharging && ![chargingBattery isAnimating]){
				if (ABReflection) {
					[chargingView setShowsReflection:YES];
				} else {
					[chargingView setShowsReflection:NO];
				}
				NSMutableArray *batteryImages = [NSMutableArray array];
				int startImage = ABFullAnimation ? 1 : ([chargingView _currentBatteryIndex]-1 > 0 ? [chargingView _currentBatteryIndex]-1 : [chargingView _currentBatteryIndex]);
				for (int i = startImage; i <= [chargingView _currentBatteryIndex]; i++){
					[batteryImages addObject:[UIImage imageNamed:[NSString stringWithFormat:[chargingView _imageFormatString],i]]];
				}
				chargingBattery.animationImages = batteryImages;
				chargingBattery.animationDuration = batteryImages.count > 4 ? batteryImages.count/4 : 1;
				chargingBattery.animationRepeatCount = 0;
				[chargingBattery startAnimating];
			}
		}
	}
}

-(void)hideChargingView{
	if (!ABAnimation){
		%orig;
		return;
	}
	SBBatteryChargingView *chargingView = [[self chargingView] chargingView];
	UIImageView *chargingBattery = MSHookIvar<UIImageView *>(chargingView,"_topBatteryView");
	[chargingBattery stopAnimating];
	%orig;
}
%end

%hook SBAwayChargingView
+ (BOOL)shouldShowDeviceBattery {
	UIDeviceBatteryState batteryState = [UIDevice currentDevice].batteryState;
	if (batteryState == UIDeviceBatteryStateUnplugged){
		if (LSBattery) return YES;
		return NO;
	} else {
		if (ABBattery) return YES;
		return NO;
	}
}
%end

%hook SBWallpaperView
- (float)alpha {
	if (ABWallpaper) return 0.0f;
	return %orig;
}
%end

static void ABReloadSettings(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
	ABSettings();
}

%ctor {
	NSAutoreleasePool *ABPool = [NSAutoreleasePool new];
	ABSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &ABReloadSettings, CFSTR("net.limneos.animatebattery.reload"), NULL, 0);
	[ABPool drain];
}
