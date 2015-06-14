//
//  GameViewController.m
//  Taker
//
//  Created by 愷愷 on 2015/6/14.
//  Copyright (c) 2015年 mobagel. All rights reserved.
//

#import "GameViewController.h"
#import "MoTaker.h"
#import "UIViewController+LewPopupViewController.h"
#import "LewPopupViewAnimationFade.h"
#import "PopupView.h"

@interface GameViewController ()

@end

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //  set delegate
    self.onlineTableView.delegate = self;
    self.onlineTableView.dataSource = self;
    
    //  get online list
    [self get_online_list];
    
    //  accept invitation
    [[MoTaker sharedInstance]accept_invitation:self];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //  get online list every 5s
    self.timer = [NSTimer scheduledTimerWithTimeInterval:ONLINE_INTERVAL
                                                  target:self
                                                selector:@selector(get_online_list)
                                                userInfo:nil
                                                 repeats:YES];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.timer invalidate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - functions 
- (void)get_online_list {
    [[[MoTaker sharedInstance]manager]GET:[API_PREFIX stringByAppendingString:@"get_online_list.php"] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
        if (error) {
            [[MoTaker sharedInstance]alert:@"Server Error" message:[error description]];
        }
        else {
            NSInteger code = [[json objectForKey:@"code"]integerValue];
            NSString* data = [json objectForKey:@"data"];
            if (code == 200) {
                self.onlinePlayers = [[NSMutableArray alloc]initWithArray:(NSArray*)data];
                [self.onlineTableView reloadData];
            }
            else {
                [[MoTaker sharedInstance]alert:@"Get Online List Failed" message:data];
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[MoTaker sharedInstance]alert:@"Internet Error" message:[error description]];
    }];

}



#pragma mark - tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.onlinePlayers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //  reuse cell
    
    static NSString *CellIdentifier = @"playerCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [self.onlinePlayers objectAtIndex:indexPath.row];
    
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *player = self.onlinePlayers[indexPath.row];
    NSLog(@"players = %@ / %@", [[MoTaker sharedInstance]account], player);
    [[[MoTaker sharedInstance]manager]POST:[API_PREFIX stringByAppendingString:@"new_round.php"]
                               parameters:@{@"player1":[[MoTaker sharedInstance]account],
                                            @"player2":player}
                                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
        if (error) {
            [[MoTaker sharedInstance]alert:@"Server Error" message:[error description]];
        }
        else {
            NSInteger code = [[json objectForKey:@"code"]integerValue];
            NSString* data = [json objectForKey:@"data"];
            if (code == 200) {
                [[MoTaker sharedInstance]setRound_id:data];
                
                PopupView *view = [PopupView defaultPopupView];
                view.parentVC = self;
                [self lew_presentPopupView:view animation:[LewPopupViewAnimationFade new] dismissed:^{
                    [self.respondTimer invalidate];
                }];
                
                self.respondTimer = [NSTimer scheduledTimerWithTimeInterval:RESPOND_INTERVAL
                                                                     target:self
                                                                   selector:@selector(get_respond)
                                                                   userInfo:nil
                                                                    repeats:YES];

            }
            else {
                [[MoTaker sharedInstance]alert:@"Create New Round Failed" message:data];
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[MoTaker sharedInstance]alert:@"Internet Error" message:[error description]];
    }];
    
}

- (void)get_respond {
    [[[MoTaker sharedInstance]manager]GET:[API_PREFIX stringByAppendingString:@"get_round.php"]
                               parameters:@{@"round_id":[[MoTaker sharedInstance]round_id]}
                                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
        if (error) {
            [[MoTaker sharedInstance]alert:@"Server Error" message:[error description]];
        }
        else {
            NSInteger code = [[json objectForKey:@"code"]integerValue];
            NSString* data = [json objectForKey:@"data"];
            if (code == 200) {
                NSDictionary *round = (NSDictionary*)data;
                [[MoTaker sharedInstance]setRound:round];
                if ([[round objectForKey:@"act"]integerValue] == 1) {
                    [self.respondTimer invalidate];
                    UIViewController *cameraVC = [self.storyboard instantiateViewControllerWithIdentifier:@"cameraVC"];
                    [self presentViewController:cameraVC animated:YES completion:nil];
                }
                NSLog(@"data = %@[%@]", data, data.class);
            }
            else {
                [[MoTaker sharedInstance]alert:@"Get Online List Failed" message:data];
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[MoTaker sharedInstance]alert:@"Internet Error" message:[error description]];
    }];

}

@end
