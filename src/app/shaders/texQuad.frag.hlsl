Texture2D<float4> tex: register(t0, space2);
SamplerState samp: register(s0, space2);

float4 main(float2 tex_coord: TEXCOORD0, float4 color: TEXCOORD1): SV_Target0 {
    return tex.Sample(samp, tex_coord) + float4(color.r, color.g, color.b, 0);
}
