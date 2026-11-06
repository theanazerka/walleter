#import "WLIcon.h"

UIImage *WLIconImage(CGFloat side, CGFloat scale, UIColor *background, UIColor *foreground, NSString *glyph, UIImage *customImage) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(side, side), NO, scale);
    CGRect rect = CGRectMake(0, 0, side, side);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:side * 0.22];

    if (customImage) {
        [path addClip];
        [[UIColor whiteColor] setFill];
        UIRectFill(rect);
        CGSize s = customImage.size;
        CGFloat k = MAX(side / MAX(s.width, 1), side / MAX(s.height, 1));   // aspect fill
        CGSize d = CGSizeMake(s.width * k, s.height * k);
        [customImage drawInRect:CGRectMake((side - d.width) / 2, (side - d.height) / 2, d.width, d.height)];
    } else {
        [background setFill];
        [path fill];
        NSString *text = glyph.length ? glyph : @"?";
        CGFloat fontSize = side * (text.length <= 1 ? 0.62 : text.length == 2 ? 0.46 : 0.34);
        UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
        CGSize ts = [text sizeWithFont:font];
        while (ts.width > side * 0.86 && fontSize > 4) {
            fontSize -= 1;
            font = [UIFont boldSystemFontOfSize:fontSize];
            ts = [text sizeWithFont:font];
        }
        [foreground setFill];
        [text drawAtPoint:CGPointMake((side - ts.width) / 2, (side - ts.height) / 2) withFont:font];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

UIImage *WLFitImage(UIImage *image, CGSize maxSize, CGFloat scale) {
    CGSize s = image.size;
    CGFloat k = MIN(maxSize.width / MAX(s.width, 1), maxSize.height / MAX(s.height, 1));
    CGSize d = CGSizeMake(floor(s.width * k), floor(s.height * k));
    UIGraphicsBeginImageContextWithOptions(d, NO, scale);
    [image drawInRect:CGRectMake(0, 0, d.width, d.height)];
    UIImage *out = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return out;
}
