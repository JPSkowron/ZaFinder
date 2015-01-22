//
//  Pizzeria.m
//  ZaHunter
//
//  Created by JP Skowron on 1/21/15.
//  Copyright (c) 2015 JP Skowron. All rights reserved.
//

#import "Pizzeria.h"

@implementation Pizzeria

-(instancetype)initWithmapItem:(MKMapItem *)mapItem{
    self = [super init];
    self.name = mapItem.name;
    self.mapItem = mapItem;
    return self;
}

@end
