Texture2D<float4> tex: register(t0, space2);
SamplerState samp: register(s0, space2);

struct FragData {
    float2 tex_coord: TEXCOORD0;
    nointerpolation float4 tex_bounds: TEXCOORD1;
    nointerpolation float2 texel_size: TEXCOORD2;
    nointerpolation float4 color: COLOR0;
    nointerpolation float outline_stroke: TEXCOORD3;
    nointerpolation float4 outline_color: COLOR1;
    float4 position: SV_Position;
};

float4 main(FragData data): SV_Target0 {
    float4 tex_sample = tex.Sample(samp, data.tex_coord);
    if (data.outline_stroke != 0 && tex_sample.a == 0) { // Candidate for outline

        // Naive solution with for loop. SDF much better, but w/e for this. SDF may require additional work for usage with atlas?
        for (int x = -data.outline_stroke; x <= data.outline_stroke; x++) {
            float test_x = data.tex_coord.x + (data.texel_size.x * x);
            test_x = clamp(test_x, data.tex_bounds[0], data.tex_bounds[1]);
            
            for (int y = -data.outline_stroke; y <= data.outline_stroke; y++) {
                float test_y = data.tex_coord.y + (data.texel_size.y * y);
                test_y = clamp(test_y, data.tex_bounds[2], data.tex_bounds[3]);

                float4 test_sample = tex.Sample(samp, float2(test_x, test_y));
                if (test_sample.a != 0) {
                    return data.outline_color;
                }

                if (y == 0) {
                    y++;
                }
            }

            if (x == 0) {
                x++;
            }
        }

        return float4(0, 0, 0, 0);
    }

    return data.color;
}
