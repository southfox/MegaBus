//
//  MBViewController.m
//  MegaBus
//
//  Created by Javier Fuchs on 9/20/16.
//  Copyright © 2016 Fuchs. All rights reserved.
//

#import "MBViewController.h"
#import <SCLAlertView.h>
#import <EXTScope.h>
#import "Megabus-Swift.h"

typedef NS_ENUM(NSUInteger, TravelMode) {
    TravelModeNone,
    TravelModeTrain,
    TravelModeBus,
    TravelModeFlight
};
        
@interface MBViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIButton *dayButton;
@property (weak, nonatomic) IBOutlet UIButton *cityButton;
@property (weak, nonatomic) IBOutlet UIButton *trainButton;
@property (weak, nonatomic) IBOutlet UIView *trainSelectedView;
@property (weak, nonatomic) IBOutlet UIButton *busButton;
@property (weak, nonatomic) IBOutlet UIView *busSelectedView;
@property (weak, nonatomic) IBOutlet UIButton *flightButton;
@property (weak, nonatomic) IBOutlet UIView *flightSelectedView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sortControl;
@property (weak, nonatomic) IBOutlet UISwitch *orderSwitch;

@property (strong, nonatomic) NSArray *busses;
@property (strong, nonatomic) NSArray *flights;
@property (strong, nonatomic) NSArray *trains;


@property (nonatomic) TravelMode travelMode;

@end

@implementation MBViewController

- (NSManagedObjectContext *)mco {
    return [MBCoreDataManager instance].taskContext;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // little trick, to show the default information (Train), is the first tab
    // there's a moment when the service MBServiceManager says it's offline/online
    // TODO: fix this in the future
    [self performSelector:@selector(travelModeAction:) withObject:self.trainButton afterDelay:1];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.travels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MBTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:[MBTableViewCell reuseIdentifier] forIndexPath:indexPath];
    MBTravel* travel = self.travels[indexPath.row];
    [cell configure:travel];
    return cell;
}

#pragma mark -
#pragma mark UITableDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    [alert showWarning:self title:@"Warning" subTitle:@"Offer details are not yet implemented!"
      closeButtonTitle:@"Close" duration:0.0f];
}


/// lazy array for the 3 tabs, unified in one, so we can call [self travels] in the table view datasource/delegate
- (NSArray *)travels {
    if (self.travelMode == TravelModeBus) {
        return self.busses;
    }
    if (self.travelMode == TravelModeFlight) {
        return self.flights;
    }
    return self.trains;
}

/// Fetch from database
- (void)fetchOffline {
    if (self.travelMode == TravelModeBus) {
        self.busses = [MBTravelBus fetch];
    }
    else if (self.travelMode == TravelModeFlight) {
        self.flights = [MBTravelFlight fetch];
    }
    else {
        self.trains = [MBTravelTrain fetch];
    }
    [self reloadData];
}


/// Request from the services if online
- (void)travelRequest {

    NSString *message = nil;
    if (self.travelMode == TravelModeBus) {
        message = @"Loading Buses...";
    }
    else if (self.travelMode == TravelModeFlight) {
        message = @"Loading Flights...";
    }
    else {
        message = @"Loading Trains...";
    }
    if ([MBServiceManager isOnline]) {

        SCLAlertView *waitingAlert = [[SCLAlertView alloc] init];

        //Using Block
        @weakify(self)
        [waitingAlert addButton:@"Show offline information" actionBlock:^(void) {
            @strongify(self);
            [self fetchOffline];
        }];
        [waitingAlert showWaiting:self title:message subTitle:@"We are retrieveing information from the server" closeButtonTitle:nil duration:0.0f];
        
        typedef void (^ServiceFailure)(NSError *error);
        ServiceFailure failureBlock = ^(NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                SCLAlertView *alertError = [[SCLAlertView alloc] init];
                [alertError showError:@"error" subTitle:error.description closeButtonTitle:@"Close" duration:0.0f];
            });
        };

        if (self.travelMode == TravelModeBus) {
            [MBServiceManager fetchBusWithSuccess:^(id  _Nullable result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @strongify(self);
                    self.busses = result;
                    [self reloadData];
                    [waitingAlert hideView];
                });
            } failure:failureBlock];
        }
        else if (self.travelMode == TravelModeFlight) {
            [MBServiceManager fetchFlightWithSuccess:^(id  _Nullable result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @strongify(self);
                    self.flights = result;
                    [self reloadData];
                    [waitingAlert hideView];
                });
            } failure:failureBlock];
        }
        else {
            [MBServiceManager fetchTrainWithSuccess:^(id  _Nullable result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @strongify(self);
                    self.trains = result;
                    [self reloadData];
                    [waitingAlert hideView];
                });
            } failure:failureBlock];
        }
    }
    else {
        SCLAlertView *alert = [[SCLAlertView alloc] init];
        [alert showWaiting:self title:@"Offline mode" subTitle:@"Retrieving information from Database."
          closeButtonTitle:nil duration:1.0f];
        [self fetchOffline];
    }
}


/// Action handler of the buttons
/// It shows a small view to indicate which is the current tab
- (IBAction)travelModeAction:(id)sender {
    self.busSelectedView.alpha = 0;
    self.flightSelectedView.alpha = 0;
    self.trainSelectedView.alpha = 0;
    if (sender == self.busButton) {
        self.busSelectedView.alpha = 1;
        self.travelMode = TravelModeBus;
    }
    else if (sender == self.flightButton) {
        self.flightSelectedView.alpha = 1;
        self.travelMode = TravelModeFlight;
    }
    else if (sender == self.trainButton) {
        self.trainSelectedView.alpha = 1;
        self.travelMode = TravelModeTrain;
    }
    [self travelRequest];
}


/// TODO: city action, probably in the future we can select the city
- (IBAction)cityAction {
    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
    alert.shouldDismissOnTapOutside = YES;
    [alert showInfo:@"TBD" subTitle:@"City change will be inplemented n the future" closeButtonTitle:@"Close" duration:0.0f];
}

/// TODO: day action, probably in the future we can select the day
- (IBAction)dayAction {
    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
    alert.shouldDismissOnTapOutside = YES;
    [alert showInfo:@"TBD" subTitle:@"Day change will be inplemented n the future" closeButtonTitle:@"Close" duration:0.0f];
}

/// Action for sort
- (IBAction)sortAction:(id)sender {
    [self reloadData];
}

/// Handy method to reload the table after a sort
- (void)reloadData {
    
    BOOL ascending = [self.orderSwitch isOn];
    NSString *key = (self.sortControl.selectedSegmentIndex == 0) ? @"departureDate" :
                    (self.sortControl.selectedSegmentIndex == 1) ? @"arrivalDate" :
                    @"durationInMinutes";
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:key ascending:ascending];
    NSArray *array = [self.travels sortedArrayUsingDescriptors:@[sort]];
    if (self.travelMode == TravelModeBus) {
        self.busses = array;
    }
    else if (self.travelMode == TravelModeFlight) {
        self.flights = array;
    }
    else {
        self.trains = array;
    }
    [self.tableView reloadData];
    
}

@end