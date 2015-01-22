//
//  ViewController.m
//  ZaHunter
//
//  Created by JP Skowron on 1/21/15.
//  Copyright (c) 2015 JP Skowron. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "Pizzeria.h"

@interface ViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UITableView *pizzaTableView;
@property NSString *distanceInMeters;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
    self.distanceInMeters = @"distanceInMeters";
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
}
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    for (CLLocation *location in locations) {
        if (location.horizontalAccuracy < 1000 && location.verticalAccuracy < 1000) {

            [self.locationManager stopUpdatingLocation];

            [self findPizzaNear:location];
            break;
        }
    }

}

-(void)findPizzaNear:(CLLocation *)location {
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc]init];
    request.naturalLanguageQuery = @"Pizza";
    request.region = MKCoordinateRegionMakeWithDistance(location.coordinate, 20000, 20000);


    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        NSArray *mapItems = response.mapItems;


        self.pizzeriaResturants = [[NSMutableArray alloc]init];

        for (MKMapItem *mapItem in mapItems) {


            Pizzeria *pizza = [[Pizzeria alloc]initWithmapItem:mapItem];
            [self.pizzeriaResturants addObject:pizza];
            pizza.distanceInMeters = [pizza.mapItem.placemark.location distanceFromLocation:location];
            NSLog(@"%f", pizza.distanceInMeters / 1609.35);
        }

        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:self.distanceInMeters ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject: sort];
        [self.pizzeriaResturants sortedArrayUsingDescriptors:sortDescriptors];

        [self.pizzaTableView reloadData];
    }];
}
/*-(void)getDirectionTo: (MKMapItem *)destination {
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc]init];
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.destination = destination;

    MKDirections *direction = [[MKDirections alloc] initWithRequest:request];
    [direction calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        NSArray *routes = response.routes;
        MKRoute *route = routes.firstObject;
        NSMutableString *instructions = [[NSMutableString alloc]init];
        for (MKRouteStep *step in route.steps) {
            NSLog(@"%@", step.instructions);
            [instructions appendFormat:@"%@\n", step.instructions];
        }
        self.textView.text = instructions;

        self.textView.text = [[response.routes.firstObject valueForKeyPath:@"steps.instructions"] componentsJoinedByString:@"\n"];
        NSLog(@"-------");
    }];*/


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.pizzeriaResturants.count > 4) {
        return 4;
    } else {
    return self.pizzeriaResturants.count;
    }
}

-(UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCellID" forIndexPath:indexPath];

    MKMapItem *pizzaMapItem;
    pizzaMapItem = [self.pizzeriaResturants objectAtIndex:indexPath.row];
    Pizzeria *pizza = [self.pizzeriaResturants objectAtIndex:indexPath.row];
    cell.textLabel.text = pizzaMapItem.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.02f mi", pizza.distanceInMeters / 1609.35];
    NSLog(@"%@", pizza);
    //Pizzeria *pizza = [self.pizzeriaResturants objectAtIndex:indexPath.row];

    return cell;
}


@end
