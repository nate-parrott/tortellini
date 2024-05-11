#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 speechEffect(float2 position, SwiftUI::Layer layer, float strength, float time) {
//    half4 current_color = layer.sample(position);
//    half4 new_color = current_color;
//
//    new_color += layer.sample(position + 1) * strength;
//    new_color -= layer.sample(position - 1) * strength;
//
//    return half4(new_color);
    float2 samplePos = position;
    samplePos.y += sin(samplePos.y / 50.0 + time) * 15.0;

    half4 color = layer.sample(samplePos);

//    if (fmod(floor(position.y / 50.0), 2.0) == 0.0) {
//        color = half4(1.0 - color.x, 1.0 - color.y, 1.0 - color.z, color.w);
//    }
    return color;
}
