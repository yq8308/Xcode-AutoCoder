//
//  SourceEditorCommand.m
//  createGetter
//
//  Created by 陈越东 on 2018/1/25.
//  Copyright © 2018年 microfastup. All rights reserved.
//

#import "SourceEditorCommand.h"
#import <Cocoa/Cocoa.h>

@interface SourceEditorCommand ()

@property (nonatomic, assign) NSInteger predicate;
@property (nonatomic, strong) NSMutableArray *indexsArray;

@property (nonatomic, assign) BOOL isVc;

@end

@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    self.predicate = NO;
    NSArray *stringArray = [NSArray arrayWithArray:invocation.buffer.lines];
    
    self.indexsArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < stringArray.count; i++) {
        if (!self.predicate) {
            [self beginPredicate:stringArray[i]];
        } else {
            if ([self endPredicate:stringArray[i]]) {
                NSMutableArray *resultArray = [self makeResultStringArray];
                
                for (int i = (int)invocation.buffer.lines.count - 1; i > 0 ; i--) {
                    NSString *stringend = stringArray[i];
                    if ([stringend containsString:@"@end"]) {
                        for (int j = (int)resultArray.count - 1; j >= 0; j--) {
                            NSArray *array = resultArray[j];
                            for (int x = (int)(array.count - 1); x >= 0; x--) {
                                [invocation.buffer.lines insertObject:array[x] atIndex:i - 1];
                            }
                        }
                    } else if ([stringend containsString:@"@implementation"]) {
                        if (completionHandler) {
                            completionHandler(nil);
                        }
                        return;
                    }
                }
                
                if (completionHandler) {
                    completionHandler(nil);
                }
                return;
                
            } else {
                //没有匹配到 end  需要匹配property
                [self predicateForProperty:stringArray[i]];
                
            }
        }
    }
    completionHandler(nil);
}

// 自动打上 init 代码
- (NSMutableArray *)makeInitStringArray
{
    NSMutableArray *itemsArray = [[NSMutableArray alloc] init];
    
    NSString *line0 = [NSString stringWithFormat:@""];
    NSString *line1 = [NSString stringWithFormat:@"- (instancetype)initWithFrame:(CGRect)frame"];
    NSString *line2 = [NSString stringWithFormat:@"{"];
    NSString *line3 = [NSString stringWithFormat:@"    if (self = [super initWithFrame:frame]) {"];
    NSString *line4 = [NSString stringWithFormat:@"        [self configSubViews];"];
    NSString *line5 = [NSString stringWithFormat:@"    }"];
    NSString *line6 = [NSString stringWithFormat:@"    return self;"];
    NSString *line7 = [NSString stringWithFormat:@"}"];
    
    NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line0, line1, line2, line3, line4, line5, line6, line7, nil];
    
    [itemsArray addObject:lineArrays];
    
    return itemsArray;
}

// 自动打上 configSubViews 代码
- (NSMutableArray *)makeConfigStringArray
{
    NSMutableArray *itemsArray = [[NSMutableArray alloc] init];
    
    NSString *line0 = [NSString stringWithFormat:@""];
    NSString *line1 = [NSString stringWithFormat:@"- (void)configSubViews"];
    NSString *line2 = [NSString stringWithFormat:@"{"];
    NSMutableArray *lineArrays0 = [[NSMutableArray alloc] initWithObjects:line0, line1, line2, nil];
    [itemsArray addObject:lineArrays0];
    
    for (int i = 0; i < self.indexsArray.count; i++) {
        
        NSString *nameStr = self.indexsArray[i][@"name"];
        
        NSString *line0 = nil;
        if (self.isVc) {
            line0 = [NSString stringWithFormat:@"    [self.view addSubview:self.%@];", nameStr];
        } else {
            line0 = [NSString stringWithFormat:@"    [self addSubview:self.%@];", nameStr];
        }
        
        NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line0, nil];
        [itemsArray addObject:lineArrays];
    }
    
    for (int i = 0; i < self.indexsArray.count; i++) {
        
        NSString *nameStr = self.indexsArray[i][@"name"];
        
        NSString *line0 = [NSString stringWithFormat:@"    [self.%@ mas_makeConstraints:^(MASConstraintMaker *make) {", nameStr];
        NSString *line1 = [NSString stringWithFormat:@""];
        NSString *line2 = [NSString stringWithFormat:@"    }];"];
        
        NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line0, line1, line2, nil];
        [itemsArray addObject:lineArrays];
    }
    
    NSString *line3 = [NSString stringWithFormat:@"}"];
    NSMutableArray *lineArrays1 = [[NSMutableArray alloc] initWithObjects:line3, nil];
    [itemsArray addObject:lineArrays1];
    
    return itemsArray;
}

// 自动打上 getters 代码
- (NSMutableArray *)makeGettersStringArray
{
    NSMutableArray *itemsArray = [[NSMutableArray alloc] init];
    
    NSString *line0 = [NSString stringWithFormat:@""];
    NSString *line1 = [NSString stringWithFormat:@"#pragma mark -- Getters"];
    NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line0, line1, nil];
    [itemsArray addObject:lineArrays];
    
    for (int i = 0; i < self.indexsArray.count; i++) {
        
        NSString *categoryStr = self.indexsArray[i][@"category"];
        NSString *nameStr = self.indexsArray[i][@"name"];
        
        if ([categoryStr isEqualToString:[NSString stringWithFormat:@"UILabel"]]) {
            NSString *line0 = [NSString stringWithFormat:@""];
            NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@", categoryStr, nameStr];
            NSString *line2 = [NSString stringWithFormat:@"{"];
            NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", nameStr];
            NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] init];", nameStr, categoryStr];
            NSString *line5 = [NSString stringWithFormat:@"        _%@.font = ;", nameStr];
            NSString *line6 = [NSString stringWithFormat:@"        _%@.textColor = ;", nameStr];
            NSString *line20 = [NSString stringWithFormat:@"    }"];
            NSString *line21 = [NSString stringWithFormat:@"    return _%@;", nameStr];
            NSString *line22 = [NSString stringWithFormat:@"}"];
            
            NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line0, line1, line2, line3, line4, line5, line6, line20, line21, line22, nil];
            [itemsArray addObject:lineArrays];
        } else if ([categoryStr isEqualToString:[NSString stringWithFormat:@"UIButton"]]) {
            NSString *line0 = [NSString stringWithFormat:@""];
            NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@", categoryStr, nameStr];
            NSString *line2 = [NSString stringWithFormat:@"{"];
            NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", nameStr];
            NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] init];", nameStr, categoryStr];
            NSString *line5 = [NSString stringWithFormat:@"        _%@.titleLabel.font = ;", nameStr];
            NSString *line6 = [NSString stringWithFormat:@"        [_%@ setTitle:  forState:UIControlStateNormal];", nameStr];
            NSString *line7 = [NSString stringWithFormat:@"        [_%@ setTitleColor:  forState:UIControlStateNormal];", nameStr];
            NSString *line8 = [NSString stringWithFormat:@"        [_%@ setImage:[UIImage imageNamed: ] forState:UIControlStateNormal];", nameStr];
            NSString *line9 = [NSString stringWithFormat:@"        [_%@ addTarget:self action:@selector(someAction) forControlEvents:UIControlEventTouchUpInside];", nameStr];
            
            NSString *line20 = [NSString stringWithFormat:@"    }"];
            NSString *line21 = [NSString stringWithFormat:@"    return _%@;", nameStr];
            NSString *line22 = [NSString stringWithFormat:@"}"];
            
            NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line0, line1, line2, line3, line4, line5, line6, line7, line8, line9, line20, line21, line22, nil];
            [itemsArray addObject:lineArrays];
        } else if ([categoryStr isEqualToString:[NSString stringWithFormat:@"UICollectionView"]]) {
            NSString *line0 = [NSString stringWithFormat:@""];
            NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@", categoryStr, nameStr];
            NSString *line2 = [NSString stringWithFormat:@"{"];
            NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", nameStr];
            
            NSString *line4 = [NSString stringWithFormat:@"        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];"];
            NSString *line5 = [NSString stringWithFormat:@"        layout.itemSize = CGSizeMake( ,  );"];
            NSString *line6 = [NSString stringWithFormat:@"        layout.minimumLineSpacing = ;"];
            NSString *line7 = [NSString stringWithFormat:@"        layout.minimumInteritemSpacing = ;"];
            NSString *line8 = [NSString stringWithFormat:@"        layout.sectionInset = UIEdgeInsetsMake( , , , );"];
            NSString *line9 = [NSString stringWithFormat:@""];
            NSString *line10 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] initWithFrame:CGRectZero collectionViewLayout:layout];", nameStr, categoryStr];
            NSString *line11 = [NSString stringWithFormat:@"        _%@.delegate = self;", nameStr];
            NSString *line12 = [NSString stringWithFormat:@"        %@.dataSource = self;", nameStr];
            NSString *line13 = [NSString stringWithFormat:@"        %@.backgroundColor = [UIColor clearColor];", nameStr];
            NSString *line14 = [NSString stringWithFormat:@"        [%@ registerClass:[ class] forCellWithReuseIdentifier:@""];", nameStr];
            
            NSString *line15 = [NSString stringWithFormat:@"    }"];
            NSString *line16 = [NSString stringWithFormat:@"    return _%@;", nameStr];
            NSString *line17 = [NSString stringWithFormat:@"}"];
            
            NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line0, line1, line2, line3, line4, line5, line6, line7, line8, line9, line10, line11, line12, line13, line14, line15, line16, line17, nil];
            [itemsArray addObject:lineArrays];
        } else {
            NSString *line0 = [NSString stringWithFormat:@""];
            NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@", categoryStr, nameStr];
            NSString *line2 = [NSString stringWithFormat:@"{"];
            NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", nameStr];
            NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] init];", nameStr, categoryStr];
            NSString *line5 = [NSString stringWithFormat:@"    }"];
            NSString *line6 = [NSString stringWithFormat:@"    return _%@;", nameStr];
            NSString *line7 = [NSString stringWithFormat:@"}"];
            
            NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line0, line1, line2, line3, line4, line5, line6, line7, nil];
            [itemsArray addObject:lineArrays];
        }
    }
    return itemsArray;
}

- (NSMutableArray *)makeResultStringArray
{
    NSMutableArray *itemsArray = [[NSMutableArray alloc] init];
    
    if (!self.isVc) {
        [itemsArray addObjectsFromArray:[self makeInitStringArray]];
    }
    [itemsArray addObjectsFromArray:[self makeConfigStringArray]];
    [itemsArray addObjectsFromArray:[self makeGettersStringArray]];
    
    return itemsArray;
}

- (void)predicateForProperty:(NSString *)string
{
    NSString *str = string;
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^@property.*;\\n$"];
    if ([pre evaluateWithObject:str]) {
        //这是一个property.
        if (![str containsString:@"IBOutlet"] && ![str containsString:@"^"] && ![str containsString:@"//"]) {
            NSString *category = @"";
            NSString *name = @"";
            
            NSRange range1 = [str rangeOfString:@"\\).*\\*" options:NSRegularExpressionSearch];
            NSString *string1 = [str substringWithRange:range1];
            NSRange range2 = [string1 rangeOfString:@"[a-zA-Z0-9_]+" options:NSRegularExpressionSearch];
            category = [string1 substringWithRange:range2];
            
            NSRange range3 = [str rangeOfString:@"\\*.*;" options:NSRegularExpressionSearch];
            NSString *string2 = [str substringWithRange:range3];
            NSRange range4 = [string2 rangeOfString:@"[a-zA-Z0-9_]+" options:NSRegularExpressionSearch];
            name = [string2 substringWithRange:range4];
            
            NSDictionary *dic = @{@"category" : category, @"name" : name};
            [self.indexsArray addObject:dic];
        }
    }
}


- (void)beginPredicate:(NSString *)string
{
    NSString *str = string;
    if ([str containsString:@"@interface"]) {
        self.predicate = YES;
        // 简单判断是 vc 还是 view
        if ([str containsString:@"ViewController"]) {
            self.isVc = YES;
        } else {
            self.isVc = NO;
        }
    }
}

- (BOOL)endPredicate:(NSString *)string
{
    if ([string containsString:@"@end"]) {
        self.predicate = NO;
        return YES;
    }
    return NO;
}

- (NSMutableArray *)indexsArray
{
    if (!_indexsArray) {
        _indexsArray = [[NSMutableArray alloc] init];
    }
    return _indexsArray;
}

@end
