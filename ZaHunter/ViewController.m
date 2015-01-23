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
#import "MapViewController.h"
@interface ViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UITableView *pizzaTableView;
@property NSString *distanceInMeters;
@property NSArray *sortedArray;
@property CLLocation *currentLocation;
@property NSMutableArray *minutesArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
    self.minutesArray = [NSMutableArray new];
    self.sortedArray = [NSMutableArray new];
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

       // NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:self.distanceInMeters ascending:YES];
       // NSArray *sortDescriptors = [NSArray arrayWithObject: sort];
       // [self.pizzeriaResturants sortUsingDescriptors:sortDescriptors];

        NSSortDescriptor *distanceDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceInMeters" ascending:YES];
        NSArray *sortDescriptors = @[distanceDescriptor];
        self.sortedArray = [self.pizzeriaResturants sortedArrayUsingDescriptors:sortDescriptors];

        [self.pizzaTableView reloadData];
        [self findLocationAndDestination];
    }];
}
-(void)findLocationAndDestination {

    [self.pizzaTableView reloadData];
    CLLocationCoordinate2D sourceCLL;
    CLLocationCoordinate2D destinationCLL;
    for (int i = 0; i < 5; i++)
    {
        Pizzeria *pizzaria = [self.pizzeriaResturants objectAtIndex:i];
        Pizzeria *pizzaria2;

        if (i == 0)
        {
            sourceCLL = CLLocationCoordinate2DMake(self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude);
            pizzaria2 = [self.pizzeriaResturants objectAtIndex:i+1];
            destinationCLL = pizzaria2.coordinate;
        }
        else if (i == 5)
        {
            sourceCLL = pizzaria.coordinate;
            destinationCLL = CLLocationCoordinate2DMake(self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude);
        }
        else
        {
            sourceCLL = pizzaria.coordinate;
            pizzaria2 = [self.pizzeriaResturants objectAtIndex:i+1];
            destinationCLL = pizzaria2.coordinate;
        }

        [self getPathDirection:sourceCLL andDestination:destinationCLL];
    }
}

-(void)getPathDirection:(CLLocationCoordinate2D)source andDestination:(CLLocationCoordinate2D)destination {

    MKPlacemark *sourcePlacemark = [[MKPlacemark alloc] initWithCoordinate:source addressDictionary:nil];
    MKMapItem *sourceMapItem = [[MKMapItem alloc] initWithPlacemark:sourcePlacemark];

    MKPlacemark *destinationPlacemark = [[MKPlacemark alloc] initWithCoordinate:destination addressDictionary:nil];
    MKMapItem *destinationMapItem = [[MKMapItem alloc] initWithPlacemark:destinationPlacemark];

    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    [request setSource:sourceMapItem];
    [request setDestination:destinationMapItem];
    [request setTransportType:MKDirectionsTransportTypeWalking];
    request.requestsAlternateRoutes = NO;

    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];

    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        MKRoute *route = response.routes.lastObject;

        NSString *time = [NSString stringWithFormat:@"%.2f", (route.expectedTravelTime)/60];
        //NSLog(@"%@",time);
        [self.minutesArray addObject:time];
        [self displayTime];
    }];

}

#pragma mark ETA

- (void)displayTime
{
    double count = 200;
    NSString *text = @"Leaving your current location,";
    for (int i = 0; i < self.minutesArray.count-1; i++)
    {
        text = [text stringByAppendingString:@"you will arrive at "];
        text = [text stringByAppendingString:[[[self.pizzeriaResturants objectAtIndex:i] mapItem] name]];
        text = [text stringByAppendingString:@" within "];
        text = [text stringByAppendingString:[self.minutesArray objectAtIndex:i]];
        text = [text stringByAppendingString:@" minutes.\nAfter that, "];
        count += [[self.minutesArray objectAtIndex:i] doubleValue];
    }
    text = [text stringByAppendingString:@"you will arrive at your starting point"];
    text = [text stringByAppendingString:@" within "];
    text = [text stringByAppendingString:[self.minutesArray lastObject]];
    text = [text stringByAppendingString:@" minutes."];
    text = [text stringByAppendingString:[NSString stringWithFormat:@"\nTotal Time: %.2f min",count]];

    self.textView.text = text;
}

#pragma mark Map Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    MapViewController *mapVC = [segue destinationViewController];
    mapVC.pizzeriaResturants = self.pizzeriaResturants;
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
    pizzaMapItem = [self.sortedArray objectAtIndex:indexPath.row];
    Pizzeria *pizza = [self.sortedArray objectAtIndex:indexPath.row];
    cell.textLabel.text = pizzaMapItem.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.02f mi", pizza.distanceInMeters / 1609.35];
    NSLog(@"%@", pizza);
    //Pizzeria *pizza = [self.pizzeriaResturants objectAtIndex:indexPath.row];

    return cell;
}


@end
