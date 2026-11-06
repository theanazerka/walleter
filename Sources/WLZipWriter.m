#import "WLZipWriter.h"
#include <zlib.h>

@implementation WLZipWriter {
    NSMutableData *_body;
    NSMutableData *_central;
    uint16_t _count;
}

- (id)init {
    if ((self = [super init])) {
        _body = [NSMutableData data];
        _central = [NSMutableData data];
    }
    return self;
}

static void put16(NSMutableData *d, uint16_t v) { uint8_t b[2] = { v & 0xFF, (v >> 8) & 0xFF }; [d appendBytes:b length:2]; }
static void put32(NSMutableData *d, uint32_t v) { uint8_t b[4] = { v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF }; [d appendBytes:b length:4]; }

- (void)addFileNamed:(NSString *)name data:(NSData *)data {
    NSData *nameData = [name dataUsingEncoding:NSUTF8StringEncoding];
    uint32_t crc = (uint32_t)crc32(crc32(0L, Z_NULL, 0), data.bytes, (uInt)data.length);
    uint32_t offset = (uint32_t)_body.length;
    uint16_t dosTime = 0, dosDate = (uint16_t)((2013 - 1980) << 9 | 1 << 5 | 1);

    put32(_body, 0x04034b50);
    put16(_body, 20);                 // version needed
    put16(_body, 0);                  // flags
    put16(_body, 0);                  // method: store
    put16(_body, dosTime);
    put16(_body, dosDate);
    put32(_body, crc);
    put32(_body, (uint32_t)data.length);
    put32(_body, (uint32_t)data.length);
    put16(_body, (uint16_t)nameData.length);
    put16(_body, 0);
    [_body appendData:nameData];
    [_body appendData:data];

    put32(_central, 0x02014b50);
    put16(_central, 20);              // version made by
    put16(_central, 20);              // version needed
    put16(_central, 0);
    put16(_central, 0);
    put16(_central, dosTime);
    put16(_central, dosDate);
    put32(_central, crc);
    put32(_central, (uint32_t)data.length);
    put32(_central, (uint32_t)data.length);
    put16(_central, (uint16_t)nameData.length);
    put16(_central, 0);               // extra
    put16(_central, 0);               // comment
    put16(_central, 0);               // disk
    put16(_central, 0);               // internal attrs
    put32(_central, 0);               // external attrs
    put32(_central, offset);
    [_central appendData:nameData];
    _count++;
}

- (NSData *)archiveData {
    NSMutableData *out = [NSMutableData dataWithData:_body];
    uint32_t centralOffset = (uint32_t)out.length;
    [out appendData:_central];
    put32(out, 0x06054b50);
    put16(out, 0);
    put16(out, 0);
    put16(out, _count);
    put16(out, _count);
    put32(out, (uint32_t)_central.length);
    put32(out, centralOffset);
    put16(out, 0);
    return out;
}

@end
