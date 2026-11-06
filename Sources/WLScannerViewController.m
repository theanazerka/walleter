#import "WLScannerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface WLScannerViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
@end

@implementation WLScannerViewController {
    void (^_completion)(WLScanResult *);
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
    AVCaptureVideoPreviewLayer *_preview;
    dispatch_queue_t _queue;
    WLBarcodeDecoder *_decoder;     // используется только на _queue
    NSString *_lastText;            // для подтверждения линейных кодов двумя кадрами
    BOOL _finished;                 // трогаем только на главном потоке
    volatile int32_t _stopped;
    UILabel *_hint;
    UIView *_line;
}

+ (BOOL)isCameraAvailable {
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] != nil;
}

- (id)initWithCompletion:(void (^)(WLScanResult *))completion {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _completion = [completion copy];
        _queue = dispatch_queue_create("walleter.scanner", DISPATCH_QUEUE_SERIAL);
        self.title = @"Сканирование";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];

    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (_device.hasTorch) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Фонарик" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleTorch)];
    }

    CGRect b = self.view.bounds;
    _line = [[UIView alloc] initWithFrame:CGRectMake(20, floor(b.size.height / 2), b.size.width - 40, 2)];
    _line.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _line.backgroundColor = [UIColor colorWithRed:1 green:0.2 blue:0.2 alpha:0.8];

    _hint = [[UILabel alloc] initWithFrame:CGRectMake(10, b.size.height - 70, b.size.width - 20, 60)];
    _hint.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _hint.backgroundColor = [UIColor clearColor];
    _hint.textColor = [UIColor whiteColor];
    _hint.shadowColor = [UIColor blackColor];
    _hint.shadowOffset = CGSizeMake(0, 1);
    _hint.textAlignment = NSTextAlignmentCenter;
    _hint.numberOfLines = 0;
    _hint.font = [UIFont boldSystemFontOfSize:15];
    _hint.text = @"Наведите камеру на штрихкод или QR-код карты";

    if (![self setupSession]) {
        _hint.text = @"Не удалось включить камеру.";
    }
    [self.view addSubview:_line];
    [self.view addSubview:_hint];
}

- (BOOL)setupSession {
    if (!_device) return NO;
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (!input) {
        NSLog(@"[Walleter] camera input error: %@", error);
        return NO;
    }

    if ([_device lockForConfiguration:NULL]) {
        if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) _device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        if ([_device respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] && _device.autoFocusRangeRestrictionSupported) {
            _device.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
        }
        [_device unlockForConfiguration];
    }

    _session = [[AVCaptureSession alloc] init];
    if ([_session canSetSessionPreset:AVCaptureSessionPreset640x480]) _session.sessionPreset = AVCaptureSessionPreset640x480;
    if (![_session canAddInput:input]) return NO;
    [_session addInput:input];

    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.alwaysDiscardsLateVideoFrames = YES;
    output.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) };
    [output setSampleBufferDelegate:self queue:_queue];
    if (![_session canAddOutput:output]) return NO;
    [_session addOutput:output];

    _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _preview.frame = self.view.bounds;
    if ([_preview respondsToSelector:@selector(connection)] && _preview.connection.isVideoOrientationSupported) {
        _preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    [self.view.layer addSublayer:_preview];
    return YES;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _preview.frame = self.view.bounds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    AVCaptureSession *session = _session;
    _stopped = 0;
    dispatch_async(_queue, ^{ [session startRunning]; });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopSession];
}

- (void)stopSession {
    _stopped = 1;
    [self setTorch:NO];
    AVCaptureSession *session = _session;
    dispatch_async(_queue, ^{ [session stopRunning]; });
}

- (void)setTorch:(BOOL)on {
    if (!_device.hasTorch) return;
    if ([_device lockForConfiguration:NULL]) {
        _device.torchMode = on ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
        [_device unlockForConfiguration];
    }
}

- (void)toggleTorch {
    [self setTorch:_device.torchMode != AVCaptureTorchModeOn];
}

- (void)cancel {
    if (_finished) return;
    _finished = YES;
    [self stopSession];
    if (_completion) _completion(nil);
}

#pragma mark - Frames (на _queue)

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (_stopped) return;
    CVImageBufferRef pb = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!pb) return;

    if (!_decoder) _decoder = [[WLBarcodeDecoder alloc] init];

    CVPixelBufferLockBaseAddress(pb, kCVPixelBufferLock_ReadOnly);
    const uint8_t *y = CVPixelBufferGetBaseAddressOfPlane(pb, 0);
    size_t w = CVPixelBufferGetWidthOfPlane(pb, 0);
    size_t h = CVPixelBufferGetHeightOfPlane(pb, 0);
    size_t bpr = CVPixelBufferGetBytesPerRowOfPlane(pb, 0);
    WLScanResult *result = [_decoder decodeGray:y width:w height:h bytesPerRow:bpr];
    CVPixelBufferUnlockBaseAddress(pb, kCVPixelBufferLock_ReadOnly);

    if (!result) return;
    // Линейные коды подтверждаем двумя одинаковыми кадрами подряд, чтобы не схватить мусор
    BOOL confirmed = result.format == WLBarcodeFormatQR || [result.text isEqualToString:_lastText];
    _lastText = result.text;
    if (!confirmed) return;

    _stopped = 1;
    dispatch_async(dispatch_get_main_queue(), ^{ [self finishWithResult:result]; });
}

- (void)finishWithResult:(WLScanResult *)result {
    if (_finished) return;
    _finished = YES;
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    [self stopSession];
    if (_completion) _completion(result);
}

@end
