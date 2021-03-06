//
//  ViewController.m
//  magnetX
//
//  Created by phlx-mac1 on 16/10/20.
//  Copyright © 2016年 214644496@qq.com. All rights reserved.
//

#import "ViewController.h"
#import "movieModel.h"
#import "breakDownHtml.h"
#import "nameTableCellView.h"
#import "NSTableView+ContextMenu.h"

@interface ViewController()<NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate,ContextMenuDelegate>

@property (weak) IBOutlet NSTextField *searchTextField;
@property (weak) IBOutlet NSProgressIndicator *indicator;
@property (weak) IBOutlet NSTextField *info;
@property (weak) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) NSMutableArray<movieModel*> *magnets;
@property (nonatomic, strong) NSString  *searchURLString;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self config];
//    [self setupTableViewDoubleAction];
    // Do any additional setup after loading the view.
}
#pragma mark - Notification

- (void)observeNotification {
    [MagnetXNotification addObserver:self selector:@selector(changeKeyword) name:MagnetXSiteChangeKeywordNotification];
    [MagnetXNotification addObserver:self selector:@selector(startAnimatingProgressIndicator) name:MagnetXStartAnimatingProgressIndicator];
    [MagnetXNotification addObserver:self selector:@selector(stopAnimatingProgressIndicator) name:MagnetXStopAnimatingProgressIndicator];
    [MagnetXNotification addObserver:self selector:@selector(makeFirstResponder) name:MagnetXMakeFirstResponder];
}
- (void)config{
    self.magnets = [NSMutableArray new];
    
    [self observeNotification];
    [self setupSearchText];
}
- (void)makeFirstResponder{
    [[self.searchTextField window] makeFirstResponder:self.searchTextField];
}
- (void)changeKeyword{

    [self resetData];
    [self startAnimatingProgressIndicator];
    
    NSString*beseURL = [selectSideRule.source stringByReplacingOccurrencesOfString:@"XXX" withString:self.searchTextField.stringValue];
    NSString*url = [beseURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];

    @WEAKSELF(self);
    [[breakDownHtml downloader] downloadHtmlURLString:url willStartBlock:^{
        
    } success:^(NSData*data) {
        
        [selfWeak.magnets addObjectsFromArray:[movieModel HTMLDocumentWithData:data]];
        
        if (selfWeak.magnets.count>0) {
            [selfWeak reloadDataAndStopIndicator];
        }else{
            [selfWeak setErrorInfoAndStopIndicator:@"源网站没有数据,切换其它源试试！"];
        }
    } failure:^(NSError *error) {
        [selfWeak setErrorInfoAndStopIndicator:@"请检查网络，或者等一下再刷新"];
    }];

}
- (void)resetData {
    [self.magnets removeAllObjects];
    dispatch_async(dispatch_get_main_queue(), ^{

    [self.tableView reloadData];
    });
}
- (void)setupSearchText{
    NSArray*searchText = @[@"武媚娘传奇",@"冰与火之歌",@"心花路放",@"猩球崛起",@"行尸走肉",@"分手大师",@"敢死队3",@"血族",@"神兽金刚之青龙再现",@"麻雀",@"暗杀教室",@"我的战争",@"海底总动员",@"咖啡公社"];
    self.searchTextField.stringValue = searchText[arc4random() % searchText.count];
    
    [self changeKeyword];
}
//- (void)setupTableViewDoubleAction {
//    NSInteger action = [[NSUserDefaults standardUserDefaults] integerForKey:@"DoubleAction"];
//    switch (action) {
//        case 0:
//            self.tableView.doubleAction = @selector(openUrlLink:);
//            break;
//        case 1:
//            self.tableView.doubleAction = @selector(queryDownloadMagnet:);
//            break;
//        default:
//            break;
//    }
//}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)setupData:(id)sender {
    
//    if (![sender isKindOfClass:[ViewController class]]) {
//        return;
//    }
    [self changeKeyword];

}
- (void)openUrlLink:(id)sender {
    NSInteger row = -1;
    if ([sender isKindOfClass:[NSButton class]]) {
        row = [self.tableView rowForView:sender];
    } else {
        row = self.tableView.selectedRow;
    }
    
    if (row<0) {
        return;
    }
    NSString*beseURL = [selectSideRule.source stringByReplacingOccurrencesOfString:@"XXX" withString:self.searchTextField.stringValue];
    NSString*url = [beseURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL*toURL =[NSURL URLWithString:url];
        [self openMagnetWith:toURL];
    });
}
- (void)copyToPasteboard:(id)sender{
    NSInteger row = -1;
    if ([sender isKindOfClass:[NSButton class]]) {
        row = [self.tableView rowForView:sender];
    } else {
        row = self.tableView.selectedRow;
    }
    
    if (row<0) {
        return;
    }
    movieModel *torrent = self.magnets[row];
    NSPasteboard*pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:@[NSStringPboardType] owner:nil];
    [pasteboard setString:torrent.magnet forType:NSStringPboardType];
}
- (IBAction)queryDownloadMagnet:(id)sender {
    NSInteger row = -1;
    if ([sender isKindOfClass:[NSButton class]]) {
        row = [self.tableView rowForView:sender];
    } else {
        row = self.tableView.selectedRow;
    }
    
    if (row<0) {
        return;
    }
    movieModel *torrent = self.magnets[row];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL*url =[NSURL URLWithString:torrent.magnet];
        [self openMagnetWith:url];
    });
}
- (void)openMagnetWith:(NSURL *)magnet {
    [[NSWorkspace sharedWorkspace] openURL:magnet];
}
#pragma mark - NSTextFieldDelegate

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    if ([notification.userInfo[@"NSTextMovement"] intValue] == NSReturnTextMovement) {
        [self setupData:self];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.magnets.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = tableColumn.identifier;
    movieModel *torrent = self.magnets[row];
    if ([identifier isEqualToString:@"nameCell"]) {
        nameTableCellView *cellView   = [tableView makeViewWithIdentifier:@"nameCell" owner:self];
        cellView.textField.stringValue = torrent.name;
        return cellView;
    }
    if ([identifier isEqualToString:@"sizeCell"]) {
        NSTableCellView *cellView      = [tableView makeViewWithIdentifier:@"sizeCell" owner:self];
        cellView.textField.stringValue = torrent.size;
        return cellView;
    }
    if ([identifier isEqualToString:@"countCell"]) {
        NSTableCellView *cellView      = [tableView makeViewWithIdentifier:@"countCell" owner:self];
        cellView.textField.stringValue = torrent.count;
        return cellView;
    }
    if ([identifier isEqualToString:@"sourceCell"]) {
        NSTableCellView *cellView      = [tableView makeViewWithIdentifier:@"sourceCell" owner:self];
        cellView.textField.stringValue = selectSideRule.site;
        return cellView;
    }
    if ([identifier isEqualToString:@"magnetCell"]) {
        NSTableCellView *cellView      = [tableView makeViewWithIdentifier:@"magnetCell" owner:self];
        cellView.textField.stringValue = torrent.magnet;
        return cellView;
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSLog(@"self.tableView.selectedRow__%ld",self.tableView.selectedRow);

}

#pragma mark - Table View Context Menu Delegate

- (NSMenu *)tableView:(NSTableView *)aTableView menuForRows:(NSIndexSet *)rows {
    NSMenu *rightClickMenu = [[NSMenu alloc] initWithTitle:@""];
    NSMenuItem *downloadItem = [[NSMenuItem alloc] initWithTitle:@"下载"
                                                          action:@selector(queryDownloadMagnet:)
                                                   keyEquivalent:@""];
    NSMenuItem *copyMagnetItem = [[NSMenuItem alloc] initWithTitle:@"复制链接"
                                                          action:@selector(copyToPasteboard:)
                                                   keyEquivalent:@""];
    NSMenuItem *openItem = [[NSMenuItem alloc] initWithTitle:@"打开介绍页面"
                                                      action:@selector(openUrlLink:)
                                               keyEquivalent:@""];
    [rightClickMenu addItem:downloadItem];
    [rightClickMenu addItem:copyMagnetItem];
    [rightClickMenu addItem:openItem];
    return rightClickMenu;
}

#pragma mark - Indicator and reload table view data

- (void)reloadDataAndStopIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
    [self stopAnimatingProgressIndicator];
    self.info.stringValue = @"加载完成!";

    [self.tableView reloadData];
    });
}

- (void)setErrorInfoAndStopIndicator:(NSString*)string{
    self.info.stringValue = string;
    [self stopAnimatingProgressIndicator];
}
#pragma mark - ProgressIndicator

- (void)startAnimatingProgressIndicator {
    self.indicator.hidden = NO;
    [self.indicator startAnimation:self];
    self.info.stringValue = @"努力加载中.....";
}

- (void)stopAnimatingProgressIndicator {
    self.indicator.hidden = YES;
    [self.indicator stopAnimation:self];
}

@end
