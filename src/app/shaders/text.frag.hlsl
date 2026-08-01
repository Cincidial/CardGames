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
    if (data.outline_color.a != 0 && sample.a <= 0.75) {
        for (int x = -outline_size; x <= outline_size; x++) {
            for (int y = -outline_size; y <= outline_size; y++) {
                if (x == 0 && y == 0) continue;

                float2 test_coords = (float2(x, y) * data.texel_size) + data.tex_coord;
                test_coords = clamp(test_coords, data.tex_bounds.xy, data.tex_bounds.zw);
                float4 test_sample = tex.Sample(samp, test_coords);

                if (test_sample.a > 0.75) return data.outline_color;
            }
        }
    }

    return float4(sample.rgb + data.color.rgb, sample.a * data.color.a);
}
