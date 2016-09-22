# iOS-Test


This is an application that consist of one screen containing 3 travel modes (Train, Buses & flights). The view has 3 tabs, each representing one of the three travel options. The cells are maintained inside the Storyboard with autolayout. I think the list is clear & readable for the user and display the following:
* logo
* departure time
* arrival time
* number of changes
* price
* duration

The class for the cell is a swift class MBTableViewCell.swift.

And to get the lists, I'm using the 3 handy APIs:
* https://api.myjson.com/bins/w60i for flights
* https://api.myjson.com/bins/3zmcy for trains
* https://api.myjson.com/bins/37yzm for buses

AFNetworking is taking care of this APIs. I've added a ServiceManager.swift that works with a plist (MBMegaBus.plist). This services uses MBCoreDataManager to get the information of every Rest API.

For image sizes, I'm using  63 for example http://cdn-goeuro.com/static_content/web/logos/63/megabus.png

If there is no data available in the returned json file then I show the last offline information from DB. Each list is ordered by departure time and offer the opportunity to switch the order to arrival time or duration (Descending or Ascending). Tapping an offer button displays an "Offer details are not yet implemented!" message to the user. The app work offline, so the data is cached using CoreData. I detect offline/online using Reachability.

It's implement my solution as an app that you can try out. It's compatible with iOS 7 and different iPhone screen sizes. The source code is in GitHub (https://github.com/southfox/MegaBus).

Information for third party libraries:
    - pod 'AFNetworking', '~> 3.1': very handy pod for networking, heavily used in the companies I've been working
    - pod 'Reachability', '~> 3.2': I think this will be deprecated soon, I could use Reachability from AFNetworking, but I'm used to this one.
    - pod 'libextobjc', '~> 0.4': @onExit, @stronfigy, @weakify are the extensions I'm using here, I found very usefull @onExit to clean up some memory, unsubscribe from observers, etc. @weakify/@strongify for to work easy and fast with weak variables in blocks and prevent retain cycles.
    - pod 'SCLAlertView-Objective-C', '~> 1.0': never used before, but the alerts are really nice.

Objective-C as the main language, I've been added swift code anyway. I found very good to mix projects with ObjC and Swift.


<u>Bonus points:</u>
I'm using Objective-C and SWIFT together. I think this is a clean, well-animated, and beautiful UI.
