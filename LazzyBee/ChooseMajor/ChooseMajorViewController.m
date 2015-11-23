//
//  ChooseMajorViewController.m
//  LazzyBee
//
//  Created by HuKhong on 11/10/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import "ChooseMajorViewController.h"
#import "MajorCollectionViewCell.h"
#import "MajorObject.h"
#import "Common.h"


#define COLLCECTIONVIEW_CELL_OFFSET 10
#define CELL_WIDTH 125
#define CELL_HEIGHT 160

#define NUMBER_OF_MAJOR 4

@interface ChooseMajorViewController ()
{
    NSMutableArray *majorsArr;
}
@end

@implementation ChooseMajorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        [self.navigationController.navigationBar setTranslucent:NO];
    }
#endif
    [self.navigationController.navigationBar setBarTintColor:COMMON_COLOR];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self setTitle:@"Major List"];
    
    UIBarButtonItem *btnCancel = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:(id)self  action:@selector(cancelButtonClick)];
    self.navigationItem.leftBarButtonItem = btnCancel;
    
    UIBarButtonItem *btnDone = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:(id)self  action:@selector(doneButtonClick)];
    self.navigationItem.rightBarButtonItem = btnDone;
    
    [collectionView registerNib:[UINib nibWithNibName:@"MajorCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"MajorCollectionViewCell"];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout*)collectionView.collectionViewLayout;
    
    collectionViewLayout.minimumInteritemSpacing = 10.0f;
    collectionViewLayout.minimumLineSpacing = 10.0f;
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    [collectionViewLayout setFooterReferenceSize:CGSizeMake(self.view.frame.size.width, 0)];
    
    collectionView.collectionViewLayout = collectionViewLayout;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                        UIViewAutoresizingFlexibleHeight |
                                        UIViewAutoresizingFlexibleTopMargin |
                                        UIViewAutoresizingFlexibleLeftMargin |
                                        UIViewAutoresizingFlexibleBottomMargin |
                                        UIViewAutoresizingFlexibleRightMargin;
    collectionView.bounces = YES;
    
    [self initialMajorData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)initialMajorData {
    NSString *currentMajor = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_SELECTED_MAJOR];
    
    majorsArr = [[NSMutableArray alloc] init];
    
    //IT
    MajorObject *itObj = [[MajorObject alloc] initWithName:@"IT" thumbnail:@"it.png" andCheckFlag:NO];
    
    if ([[currentMajor lowercaseString]isEqualToString:@"it"]) {
        itObj.checkFlag = YES;
    }
    
    [majorsArr addObject:itObj];
    
    //Science
    MajorObject *scienceObj = [[MajorObject alloc] initWithName:@"Science" thumbnail:@"science.png" andCheckFlag:NO];
    
    if ([[currentMajor lowercaseString]isEqualToString:@"science"]) {
        scienceObj.checkFlag = YES;
    }
    
    [majorsArr addObject:scienceObj];
    
    //Economic
    MajorObject *economicObj = [[MajorObject alloc] initWithName:@"Economic" thumbnail:@"economic.png" andCheckFlag:NO];
    
    if ([[currentMajor lowercaseString]isEqualToString:@"economic"]) {
        economicObj.checkFlag = YES;
    }
    
    [majorsArr addObject:economicObj];
    
    //Medicine
    MajorObject *medObj = [[MajorObject alloc] initWithName:@"Medicine" thumbnail:@"medicine.png" andCheckFlag:NO];
    
    if ([[currentMajor lowercaseString]isEqualToString:@"medicine"]) {
        medObj.checkFlag = YES;
    }
    
    [majorsArr addObject:medObj];
    
    //blank
    MajorObject *blankObj = [[MajorObject alloc] initWithName:@"Coming soon" thumbnail:@"blank.png" andCheckFlag:NO];
    blankObj.enabled = NO;
    [majorsArr addObject:blankObj];
    
    //blank
    MajorObject *blankObj2 = [[MajorObject alloc] initWithName:@"Coming soon" thumbnail:@"blank.png" andCheckFlag:NO];
    blankObj2.enabled = NO;
    [majorsArr addObject:blankObj2];
}

- (void)cancelButtonClick {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneButtonClick {
    BOOL found = NO;
    for (MajorObject *majorObj in majorsArr) {
        if (majorObj.checkFlag == YES) {
            found = YES;
            [[Common sharedCommon] saveDataToUserDefaultStandard:majorObj.majorName withKey:KEY_SELECTED_MAJOR];
            break;
        }
    }
    
    if (found == NO) {
        [[Common sharedCommon] clearUserDefaultStandardWithKey:KEY_SELECTED_MAJOR];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeMajor" object:nil];
}

#pragma mark - UICollectionView Datasource
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    
    return [majorsArr count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MajorCollectionViewCell *majorCell =
    [collectionView dequeueReusableCellWithReuseIdentifier:@"MajorCollectionViewCell"
                                              forIndexPath:indexPath];
    
//    majorCell.delegate = (id)self;
    
//    // border radius
//    [majorCell.layer setCornerRadius:3.0f];
//    
//    // border
//    [majorCell.layer setBorderColor:COMMON_COLOR.CGColor];
//    [majorCell.layer setBorderWidth:3.0f];
    
    MajorObject *majorObject = [majorsArr objectAtIndex:indexPath.row];
    
    majorCell.lbMajorName.text = majorObject.majorName;
    majorCell.imgThumbnail.image = [UIImage imageNamed:majorObject.majorThumbnail];
    majorCell.imgCheck.hidden = !majorObject.checkFlag;
    majorCell.userInteractionEnabled = majorObject.enabled;
    
    if (majorObject.enabled == NO) {
        majorCell.alpha = 0.5;
    } else {
        majorCell.alpha = 1.0;
    }
    
    return majorCell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)colView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MajorObject *selectedObject = [majorsArr objectAtIndex:indexPath.row];
    selectedObject.checkFlag = !selectedObject.checkFlag;
    
    for (MajorObject *majorObj in majorsArr) {
        if (![majorObj isEqual:selectedObject]) {
            majorObj.checkFlag = NO;
        }
    }
   
    [collectionView reloadData];

    
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

#pragma mark – UICollectionViewDelegateFlowLayout

// 1
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 2
    CGSize retval = CGSizeMake(CELL_WIDTH, CELL_HEIGHT);
    retval.height += 0; retval.width += 0;
    
    return retval;
}

// 3
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(COLLCECTIONVIEW_CELL_OFFSET, COLLCECTIONVIEW_CELL_OFFSET, COLLCECTIONVIEW_CELL_OFFSET, COLLCECTIONVIEW_CELL_OFFSET);
}
@end
