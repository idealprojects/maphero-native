#import "MHFoundation.h"

NS_ASSUME_NONNULL_BEGIN

/** Options for ``MHAttributedExpression/attributes``. */
typedef NSString *MHAttributedExpressionKey NS_TYPED_ENUM;

/** The font name string array expression used to format the text. */
FOUNDATION_EXTERN MH_EXPORT MHAttributedExpressionKey const MHFontNamesAttribute;

/** The font scale number expression relative to ``MHSymbolStyleLayer/textFontSize`` used to format
 * the text. */
FOUNDATION_EXTERN MH_EXPORT MHAttributedExpressionKey const MHFontScaleAttribute;

/** The font color expression used to format the text. */
FOUNDATION_EXTERN MH_EXPORT MHAttributedExpressionKey const MHFontColorAttribute;

/**
 An ``MHAttributedExpression`` object associates text formatting attibutes (such as font size or
 font names) to an `NSExpression`.

 ### Example
 ```swift
 let redColor = UIColor.red
 let expression = NSExpression(forConstantValue: "Foo")
 let attributes: [MHAttributedExpressionKey: NSExpression] = [.fontNamesAttribute :
 NSExpression(forConstantValue: ["DIN Offc Pro Italic", "Arial Unicode MS Regular"]),
                                                               .fontScaleAttribute:
 NSExpression(forConstantValue: 1.2), .fontColorAttribute: NSExpression(forConstantValue: redColor)]
 let attributedExpression = MHAttributedExpression(expression, attributes:attributes)
 ```

 */
MH_EXPORT
@interface MHAttributedExpression : NSObject

/**
 The expression content of the receiver as `NSExpression`.
 */
@property (strong, nonatomic) NSExpression *expression;

#if TARGET_OS_IPHONE
/**
 The formatting attributes dictionary.
 Key | Value Type
 --- | ---
 ``MHFontNamesAttribute`` | An `NSExpression` evaluating to an `NSString` array.
 ``MHFontScaleAttribute`` | An `NSExpression` evaluating to an `NSNumber` value.
 ``MHFontColorAttribute`` | An `NSExpression` evaluating to an `UIColor`.

 */
@property (strong, nonatomic, readonly)
    NSDictionary<MHAttributedExpressionKey, NSExpression *> *attributes;
#else
/**
 The formatting attributes dictionary.
 Key | Value Type
 --- | ---
 ``MHFontNamesAttribute`` | An `NSExpression` evaluating to an `NSString` array.
 ``MHFontScaleAttribute`` | An `NSExpression` evaluating to an `NSNumber` value.
 ``MHFontColorAttribute`` | An `NSExpression` evaluating to an `NSColor` on macos.
 */
@property (strong, nonatomic, readonly)
    NSDictionary<MHAttributedExpressionKey, NSExpression *> *attributes;
#endif

/**
 Returns an ``MHAttributedExpression`` object initialized with an expression and no attribute
 information.
 */
- (instancetype)initWithExpression:(NSExpression *)expression;

/**
 Returns an ``MHAttributedExpression`` object initialized with an expression and text format
 attributes.
 */
- (instancetype)
    initWithExpression:(NSExpression *)expression
            attributes:(nonnull NSDictionary<MHAttributedExpressionKey, NSExpression *> *)attrs;

/**
 Creates an ``MHAttributedExpression`` object initialized with an expression and the format
 attributes for font names and font size.
 */
+ (instancetype)attributedExpression:(NSExpression *)expression
                           fontNames:(nullable NSArray<NSString *> *)fontNames
                           fontScale:(nullable NSNumber *)fontScale;

/**
 Creates an ``MHAttributedExpression`` object initialized with an expression and the format
 attributes dictionary.
 */
+ (instancetype)
    attributedExpression:(NSExpression *)expression
              attributes:(nonnull NSDictionary<MHAttributedExpressionKey, NSExpression *> *)attrs;

@end

NS_ASSUME_NONNULL_END
