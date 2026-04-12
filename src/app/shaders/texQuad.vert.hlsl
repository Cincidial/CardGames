cbuffer UniformBlock : register(b0, space1)
{
    float4x4 projection: packoffset(c0);
};

struct Input {
    float2 tex_coord: TEXCOORD0;
    float2 position: TEXCOORD1;
};

struct Output {
    float2 tex_coord: TEXCOORD0;
    float4 color: TEXCOORD1;
    float4 position: SV_Position;
};

Output main(Input input) {
    Output output;
    output.tex_coord = input.tex_coord;
    output.position = mul(projection, float4(input.position, 0, 1.0f));
    output.color = float4(0.0f, 0.0f, 0.0f, 0.0f);

    return output;
}
