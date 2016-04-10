//
//  ViewController.m
//  GrammyPlus
//
//  Created by 嵇昊雨 on 4/10/16.
//  Copyright © 2016 嵇昊雨. All rights reserved.
//

#import "ViewController.h"
#import "NXOAuth2.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (weak, nonatomic) IBOutlet UIButton *logOutButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (void) showAlertMessage:(NSString *) myMessage;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.logOutButton.enabled = false;
    self.refreshButton.enabled = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)logInButtonTapped:(id)sender {
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"Instagram"];
    self.logInButton.enabled = false;
    self.logOutButton.enabled = true;
    self.refreshButton.enabled = true;
}


- (IBAction)logOutButtonTapped:(id)sender {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *instagramAccounts = [store accountsWithAccountType:@"Instagram"];
    for(id acct in instagramAccounts){
        [store removeAccount:acct];
    }
    self.logOutButton.enabled = false;
    self.refreshButton.enabled = false;
    self.logInButton.enabled = true;
    
}

- (IBAction)refreshButtonTapped:(id)sender {
    NSArray *instagramAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"Instagram"];
    
    if([instagramAccounts count] == 0){
        NSLog(@"Warning %ld account logged in! \n", (long)[instagramAccounts count]);
        return;
    }
    
    NXOAuth2Account *acct = instagramAccounts[0];
    NSString *token = acct.accessToken.accessToken;
    
    NSString *urlStr = [@"https://api.instagram.com/v1/users/self/media/recent/?access_token=" stringByAppendingString:token];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLSession *session = [NSURLSession sharedSession];
    
    [[session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
        
        
        //Check for network error
        if(error){
            [self showAlertMessage:[NSString stringWithFormat:@"Error: Couldn't finish request: %@", error]];
            return;
        }
        
        
        //Check for http error
        NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
        if(httpRes.statusCode < 200 || httpRes.statusCode >= 300){
            [self showAlertMessage:[NSString stringWithFormat:@"Error: Got status code: %ld", (long)httpRes.statusCode]];
            return;
        }
        
        
        //Check for JSON error
        NSError *parseError;
        id pkg = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if(!pkg){
            [self showAlertMessage:[NSString stringWithFormat:@"Error: Could not parse response: %@", parseError]];
            return;
        }
        
        
        NSString *imageURLStr = pkg[@"data"][0][@"images"][@"standard_resolution"][@"url"];
        
        NSURL *imageURL = [NSURL URLWithString:imageURLStr];
        [[session dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
            //Check for network error
            if(error){
                [self showAlertMessage:[NSString stringWithFormat:@"Error: Couldn't finish request: %@", error]];
                return;
            }
            
            
            //Check for http error
            NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
            if(httpRes.statusCode < 200 || httpRes.statusCode >= 300){
                [self showAlertMessage:[NSString stringWithFormat:@"Error: Got status code: %ld", (long)httpRes.statusCode]];
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = [UIImage imageWithData:data];
            });
        
        }] resume];
        
    }] resume];
    
    
    
}

- (void) showAlertMessage:(NSString *)myMessage{
    UIAlertController *alertController;
    alertController = [UIAlertController alertControllerWithTitle:@"Alert" message:myMessage preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"confirm" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:true completion:nil];
}


@end
