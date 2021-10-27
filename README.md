# iMRuby

## Installation

iMRuby is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'iMRuby'
```

## Class UML
![class_uml](./class_uml.png)

## Usage
iMRuby usage is like JavascriptCore of iOS.
[aticle url](https://mp.weixin.qq.com/s?__biz=MzkxMjAxNDI1MQ==&mid=2247483661&idx=1&sn=f20222c330af17a27d203e913073f710&chksm=c1122fc9f665a6dfb0fa720535e59257fe640b4c4abe4f324eaeca38919f6b2cf2ea68ce5e62&token=658452920&lang=zh_CN#rd)

Ruby and OC are converted to each other
|  OC type   | Ruby type  |
|  ----  | ----  |
| nil | nil |
| NSNull  | nil |
| NSString  | string, symbol |
| NSNumber  | Fixnum, Float, boolean |
| NSDictionary  | Hash |
| NSArray  | Array |
| NSDate  | Time |
| NSBlock  | Wrapper object ruby class MRBCocoa::Block |
| id/NSObject  |  Wrapper object ruby class MRBCocoa::Object |
| class  | Wrapper object ruby class MRBCocoa::Klass |
| CGPoint  | specific Hash {'x' => 1, 'y' => 1} |
| CGSize  | specific Hash {'width' => 1, 'height' => 1} |
| CGRect  |  specific Hash {'x' => 1, 'y' => 1, 'width' => 1, 'height' => 1}|
| NSRange  | specific Hash {'location' => 0, 'length' => 1} |

#### create `MRBContext` instance
``` objective-c
self.context = [[MRBContext alloc] init];
```

#### run ruby script
``` objective-c
[self.context evaluateScript:@"puts \"Happy Niu year!\""];
# => Happy Niu year!
```

#### catch exception
``` objective-c
self.context.exceptionHandler = ^(NSError * _Nonnull exception) {
        NSLog(@"%@", exception.userInfo[@"msg"]);
    };
[self.context evaluateScript:@"happy_nui_year(2021)"];
# => undefined method 'happy_niu_year' (NOMethodError)
```

#### register constant
``` objective-c
[self.context registerConst:@"Niu" value:@"Happy Niu year!"];
[self.context evaluateScript:@"puts MRBCocoa::Const::Niu"];
# => Happy Niu year!
```

#### register method
``` objective-c
[self.context registerFunc:@"happy_niu_year" block:^NSInteger(int a, int b){
    NSLog(@"start...");
    int sum = a + b;
    NSLog(@"finish...");
    return sum;
 }];
 MRBValue *sum = [self.context evaluateScript:@"MRBCocoa.happy_niu_year(2020,1)"];
 NSInteger niu_year = sum.toInt64;
 NSLog(@"%@", @(niu_year));
# => start...
# => finish...
# => 2021
```

#### register method or constant by subscript
``` objective-c
self.context[@"Niu"] = @"Happy Niu year!";
self.context[@"happy_niu_year"] = ^NSInteger(int a, int b) {
     NSLog(@"start...");
     int sum = a + b;
     NSLog(@"finish...");
    return sum;
};
MRBValue *sum = [self.context evaluateScript:@"puts MRBCocoa::Const::Niu;MRBCocoa.happy_niu_year(2020,1)"];
NSInteger niu_year = sum.toInt64;
NSLog(@"%@", @(niu_year));
```

#### ruby invoke OC object method
``` objective-c
// OC .m file
@interface Person : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int age;
- (NSString *)say_something:(NSString *)message;
- (void)coding:(NSString *)code finished:(BOOL(^)(NSString *name, int age))finished;
@end
@implementation Person
- (NSString *)say_something:(NSString *)message
{
    NSLog(@"%@", message);
    return [self.name stringByAppendingString:message];
}
- (void)coding:(NSString *)code finished:(BOOL(^)(NSString *name, int age))finished
{
    NSLog(@"I am coding %@", code);
    if (finished) {
        BOOL f = finished(self.name, self.age);
        NSLog(@"Block return value: %@", @(f));
    }
}
@end
```
``` ruby
# ruby .rb file
require_cocoa 'Person'

person = Person.alloc.init
person.setName_('anan')
person.setAge_(2)
message = person.say__something_("happy Niu year!")
puts message

finished = Proc.new {|name, age| puts "I am #{name}, #{age} year old"; true}
finished_block = finished.to_cocoa_block("BOOL, NSString *, int");
person.coding_finished_("Ruby", finished_block)

```

#### invoke OC method rules:  
1. replace ':' with '_'
```
- (NSString *)saySomething:(NSString *)message;
message = person.saySomething_("happy Niu year!")
```

2. replace '_' with '__'
```
- (NSString *)say_something:(NSString *)message;
message = person.say__something_("happy Niu year!")
```

3. if '_' or '__' is in the head of oc mehtod name, do nothing
```
- (NSString *)__say_something:(NSString *)message;
message = person.__say__something_("happy Niu year!")
```
4. if oc method has a NSBlock parameter, can use `to_cocoa_block` to convert `Proc` to `NSBlock`
```
- (void)coding:(NSString *)code finished:(BOOL(^)(NSString *name, int age))finished;

// ruby
finished = Proc.new {|name, age| puts "I am #{name}, #{age} year old"; true}
finished_block = finished.to_cocoa_block("BOOL, NSString *, int");
person.coding_finished_("Ruby", finished_block)
```

## Author

ping.cao

## License

iMRuby is available under the MIT license. See the LICENSE file for more info.
