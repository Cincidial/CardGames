Texture2D<float4> tex: register(t0, space2);
SamplerState samp: register(s0, space2);

struct FragData {
    float2 tex_coord: TEXCOORD0;
    nointerpolation float4 tex_bounds: TEXCOORD1;
    nointerpolation float2 texel_size: TEXCOORD2;
    nointerpolation float4 color: COLOR0;
    nointerpolation float4 outline_color: COLOR1;
    float4 position: SV_Position;
};

static const int outline_size = 1;
float4 main(FragData data): SV_Target0 {
    float4 sample = tex.Sample(samp, data.tex_coord);
    if (data.outline_color.a != 0 && sample.a == 0) {
        for (int x = -outline_size; x <= outline_size; x++) {
            float test_x = data.tex_coord.x + (data.texel_size.x * x);
            test_x = clamp(test_x, data.tex_bounds[0], data.tex_bounds[2]);

            for (int y = -outline_size; y <= outline_size; y++) {
                float test_y = data.tex_coord.y + (data.texel_size.y * y);
                test_y = clamp(test_y, data.tex_bounds[1], data.tex_bounds[3]);

                float4 test_sample = tex.Sample(samp, float2(test_x, test_y));
                if (test_sample.a != 0) {
                    return data.outline_color;
                }
            }
        }

        return sample;
    }

    return float4(sample.rgb + data.color.rgb, sample.a * data.color.a);
}
