#import "MHStyleValue_Private.h"

#include <mbgl/style/expression/expression.hpp>

const MHStyleFunctionOption MHStyleFunctionOptionInterpolationBase = @"MHStyleFunctionOptionInterpolationBase";
const MHStyleFunctionOption MHStyleFunctionOptionDefaultValue = @"MHStyleFunctionOptionDefaultValue";

id MHJSONObjectFromMBGLValue(const mbgl::Value &value) {
    return value.match([](const mbgl::NullValue) -> id {
        return [NSNull null];
    }, [](const bool value) {
        return @(value);
    }, [](const float value) {
        return @(value);
    }, [](const int64_t value) {
        return @(value);
    }, [](const uint64_t value) {
        return @(value);        
    }, [](const double value) {
        return @(value);
    }, [](const std::string &value) {
        return @(value.c_str());
    }, [](const mbgl::Color &value) {
        return [MHColor mgl_colorWithColor:value];
    }, [](const mbgl::style::Position &value) {
        std::array<float, 3> spherical = value.getSpherical();
        MHSphericalPosition position = MHSphericalPositionMake(spherical[0], spherical[1], spherical[2]);
        return [NSValue valueWithMHSphericalPosition:position];
    }, [&](const std::vector<mbgl::Value> &vector) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:vector.size()];
        for (auto value : vector) {
            [array addObject:MHJSONObjectFromMBGLValue(value)];
        }
        return array;
    }, [&](const std::unordered_map<std::string, mbgl::Value> &map) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:map.size()];
        for (auto &item : map) {
            dictionary[@(item.first.c_str())] = MHJSONObjectFromMBGLValue(item.second);
        }
        return dictionary;
    }, [](const auto &) -> id {
        return nil;
    });
}

id MHJSONObjectFromMBGLExpression(const mbgl::style::expression::Expression &mbglExpression) {
    return MHJSONObjectFromMBGLValue(mbglExpression.serialize());
}


std::unique_ptr<mbgl::style::expression::Expression> MHClusterPropertyFromNSExpression(NSExpression *expression) {
    if (!expression) {
        return nullptr;
    }

    NSArray *jsonExpression = expression.mgl_jsonExpressionObject;

    auto expr = mbgl::style::expression::dsl::createExpression(mbgl::style::conversion::makeConvertible(jsonExpression));

    return expr;
}
