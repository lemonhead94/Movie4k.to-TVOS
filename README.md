# Movie4k.to
> A TVOS Application for the AppleTV 4 / tvOS 9.2 for the Website [Movie4k.to](www.movie4k.to)

This is more "a prove of concept" than an actual app, as it's scraps the website for solely the links...

## Screenshots
![Cinema Movies](https://github.com/lemonhead94/Movie4k.to-TVOS/blob/master/Screenshots/1_CinemaMovies.png)
![Features Series](https://github.com/lemonhead94/Movie4k.to-TVOS/blob/master/Screenshots/2_FeaturedSeries.png)
![Search](https://github.com/lemonhead94/Movie4k.to-TVOS/blob/master/Screenshots/3_Search.png)
![Serie Preview Season](https://github.com/lemonhead94/Movie4k.to-TVOS/blob/master/Screenshots/4_Serie_Season.png)
![Serie Preview Episode](https://github.com/lemonhead94/Movie4k.to-TVOS/blob/master/Screenshots/5_Serie_Episode.png)
![Movie Preview](https://github.com/lemonhead94/Movie4k.to-TVOS/blob/master/Screenshots/6_MoviePreview.png)

## Credits
Thanks for the AppIcon [u/Thrizer](https://www.reddit.com/user/Thrizer) :smile:

## Prerequirements
- API-Key from the [The Movie Database (TMDb)](https://www.themoviedb.org)

## How to get an API-Key?
1. Make an account [here](https://www.themoviedb.org/account/signup?language=en)
2. Login and click on your account name
3. On the left handside, click on API
4. Then "To generate a new API key, click here."
5. Click on Developer -> Accept Agreement
6. fill out the form, no real info required and use the flair Education
7. Copy the new API-Key and paste it into the Settings.plist

## Sideloading
1. download Repo
2. pod install
3. Got to /Movie4k.to-TVOS/Movie4K/Pods/SVProgressHUD/SVProgressHUD/**SVProgressHUD.m**
4. search for "- (void)updateHUDFrame {" and change the hudWidth and hudHeight to 300.0f  (this is a workaround for now)
5. now you can sideload the app like usual...


## Dependencies
- SwiftyJSON
- Alamofire
- HTMLReader
- Cosmos
- MarqueeLabel/Swift
- SVProgressHUD
- PromiseKit

## License
You can do whatever you want with this project. Would be cool if you make pull request, so it's all in one place, but not necessary. :relaxed:
