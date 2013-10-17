# vinylogue for Last.fm

Vinylogue is a simple Last.fm client for iOS that shows you and your friends' charts from previous years.

* [App Store](https://itunes.apple.com/us/app/vinylogue-for-last.fm/id617471119?ls=1&mt=8) (it's free).
* [Landing page](http://twocentstudios.com/apps/vinylogue/) with screenshots.
* [Blog post](http://twocentstudios.com/blog/2013/04/03/the-making-of-vinylogue/) walking through the source.

![Screenshot 1](http://twocentstudios.com/apps/vinylogue/img/ss-charts.png)
![Screenshot 2](http://twocentstudios.com/apps/vinylogue/img/ss-friends.png)
![Screenshot 3](http://twocentstudios.com/apps/vinylogue/img/ss-album.png)

## Getting started

Apologies, this is a little cumbersome.

1. Clone the repo. `$ git clone git://github.com/twocentstudios/vinylogue.git`
2. Install the pods. `$ pod install`
3. Open `vinylogue.xcworkspace`.
4. Create a new header file called `TCSVinylogueSecret.h`
5. Copy and paste this code into `TCSVinylogueSecret.h`.
	
		#define kFlurryAPIKey @""  
		#define kCrashlyticsAPIKey @""  
		#define kTestFlightAPIKey @""  
		#define kTCSLastFMAPIKeyString @"YOUR_API_KEY"  
6. Add your API keys to the above code (Only the Last.fm one is required).
7. Remove `Crashlytics.framework` from the Targets->Build Phases->Link Binary With Libraries menu. 
8. Delete the "Run Script" build phase from the same menu.
9. Build!

## Learn

This project was both an app I wanted to exist, and a learning experience for me regarding [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa). I hope other iOS devs can learn from it. I haven't done much open source in the past, and have learned by studying the source great projects such as [Cheddar](https://github.com/nothingmagical/cheddar-ios) and [news:yc](https://github.com/Xuzz/newsyc) (amongst many others), so it felt like it was time to give back.

I wrote a pretty extensive [blog post](http://twocentstudios.com/blog/2013/04/03/the-making-of-vinylogue/) covering several parts of the design and development of this app. If you're looking for a guided tour through the source, check that out first.

## License

License for source is Modified BSD. If there's enough interest, I can modularize particular parts of the source into their own MIT Licensed components.

All rights are reserved for image assets.

This is very much an experiment for me that I'm hoping doesn't backfire. If you'd like to improve the app, please fork and submit pull requests and we'll keep one version on the App Store for everyone to enjoy. Don't charge for other versions (I'm pretty sure it violates Last.fm's TOS anyway).

## About

Vinylogue was created by [Christopher Trott](http://twitter.com/twocentstudios). My development shop is called [twocentstudios](http://twocentstudios.com).
