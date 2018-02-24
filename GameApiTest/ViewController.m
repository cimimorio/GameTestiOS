//
//  ViewController.m
//  GameApiTest
//
//  Created by apple on 2018/2/9.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<NSStreamDelegate,UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate>
{
	NSInputStream *_input_s;
	NSOutputStream *_output_s;
	NSRunLoop *loadDataRunloop;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *resetSreamBtn;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (strong) NSThread *socketThread;

@property (strong) NSMutableArray *dataArr;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
	self.dataArr = [[NSMutableArray alloc] init];
	[self.dataArr addObject:@"qqqqqqqqqq"];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	
	[self startSockect];
}

- (IBAction)resetStreamBtnAction:(id)sender {
	[self stopStream];
}

- (IBAction)sendBtnAction:(id)sender {
	if (self.textField.text.length > 0 && _output_s != nil) {
		NSData *data = [self.textField.text dataUsingEncoding:NSUTF8StringEncoding];
		[_output_s write:data.bytes maxLength:data.length];
	}
}

- (IBAction)addGameBtnAction:(id)sender {
	NSString *playerID = @"111111";
	NSString *roomID = @"10002";
	NSString *api = [NSString stringWithFormat:@"http://localhost:8080/room/addgame/%@/%@",playerID,roomID];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:api]];
	[request setTimeoutInterval:3];
	[request setHTTPMethod:@"GET"];
	NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSString *result = nil;
			if (error) {
				NSLog(@"%s--%@",__FUNCTION__,error);
				result = [error description];
			}else{
				NSError *err;
//				result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&err];
//				NSLog(@"%@----%@",result,err);
			}
			if (result == nil) {
				return;
			}
			NSLog(@"%@",result);
			[self.dataArr addObject:[NSString stringWithFormat:@"%@",result]];
			[self.tableView beginUpdates];
			[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.dataArr.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
			[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataArr.count - 2 inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
			[self.tableView endUpdates];
		});
		
	}];
	[task resume];
}

- (void)reloadData{
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:@"http:127.0.0.1:8080/room/test"]];
	[request setTimeoutInterval:3];
	[request setHTTPMethod:@"GET"];
	NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		if (error) {
			NSLog(@"%s--%@",__FUNCTION__,error);
		}
	}];
	[task resume];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	NSString *msg = [self.dataArr objectAtIndex:indexPath.row];
	[cell.textLabel setText:msg];
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return self.dataArr.count;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
	[self.textField endEditing:YES];
}

- (void)startSockect{
	self.socketThread = [[NSThread alloc] initWithTarget:self selector:@selector(initStream) object:nil];
	[self.socketThread start];
}

- (void)stopStream{
	[_output_s close];
	[_output_s removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
	[_output_s setDelegate:nil];
	[_input_s close];
	[_input_s removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
	[_input_s setDelegate:nil];
	if (loadDataRunloop) {
		CFRunLoopStop([loadDataRunloop getCFRunLoop]);
		loadDataRunloop = nil;
	}
}

- (void)initStream{
	
	NSString *host = @"127.0.0.1";
	int port = 8080;
	
	CFReadStreamRef read_s;
	CFWriteStreamRef write_s;
	CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &read_s, &write_s);
	//代理来通知连接建立是否成功，把C语言的输入输出流转化成OC对象，使用桥接转换。
	_input_s = (__bridge NSInputStream *)(read_s);
	_output_s = (__bridge NSOutputStream *)(write_s);
	_input_s.delegate = _output_s.delegate = self;
	// 把输入输出流添加到主运行循环,否则代理可能不工作
	[_input_s scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_output_s scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	// 打开输入输出流
	[_input_s open];
	[_output_s open];
	loadDataRunloop = [NSRunLoop currentRunLoop];
	[loadDataRunloop run];
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
	switch (eventCode) {
		case NSStreamEventNone:{
			NSLog(@"%s--stream event none",__FUNCTION__);
		}
			break;
		case NSStreamEventErrorOccurred:{
			NSLog(@"%s--stream event error occured--%@",__FUNCTION__,aStream.streamError);
		}
			break;
		case NSStreamEventOpenCompleted:{
			NSLog(@"%s--stream open complete",__FUNCTION__);
		}
			break;
		case NSStreamEventEndEncountered:{
			NSLog(@"%s--stream end encountered",__FUNCTION__);
			NSLog(@"Error:%ld:%@",[[aStream streamError] code], [[aStream streamError] localizedDescription]);

		}
			break;
		case NSStreamEventHasBytesAvailable:{
			NSLog(@"%s--stream even has bytes avilable",__FUNCTION__);
			if (aStream == _input_s) {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSMutableData *input = [[NSMutableData alloc] init];
					uint8_t buffer[1024];
					long len;
					while([_input_s hasBytesAvailable])
					{
						len = [_input_s read:buffer maxLength:sizeof(buffer)];
						if (len > 0)
						{
							[input appendBytes:buffer length:len];
						}
					}
					NSString *resultstring = [[NSString alloc] initWithData:input encoding:NSUTF8StringEncoding];
					if ([resultstring containsString:@"ping"]) {
						return;
					}
					NSLog(@"接收:%@",resultstring);
					[self.dataArr addObject:resultstring];
					[self.tableView beginUpdates];
					[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.dataArr.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
					[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataArr.count - 2 inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
					[self.tableView endUpdates];
//
				});
			}
		}
			break;
		case NSStreamEventHasSpaceAvailable:{
			NSLog(@"%s--stream even has space available",__FUNCTION__);
//			if (aStream == _output_s) {
//				//输出
//				UInt8 buff[] = "Hello Server!";
//				[_output_s write:buff maxLength: strlen((const char*)buff)+1];
//				//必须关闭输出流否则，服务器端一直读取不会停止，
//				[_output_s close];
//			}
		}
			break;
		default:
			break;
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


@end
