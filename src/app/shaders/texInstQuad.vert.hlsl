cbuffer UniformBlock : register(b0, space1)
{
    float4x4 projection: packoffset(c0);
};
cbuffer UniformBlock : register(b1, space1)
{
    float2 atlas_dimensions: packoffset(c0);
};

struct InstanceData {
    float2 tex_coord; // The pixel values
    float2 tex_dimensions; // The pixel values
    float2 position;
    float2 scale;
    float4 color;
};
StructuredBuffer<InstanceData> DataBuffer: register(t0, space0);

struct Output {
    float2 tex_coord: TEXCOORD0;
    float4 color: TEXCOORD1;
    float4 position: SV_Position;
};

static const uint triangle_indices[6] = {2, 3, 0, 1, 0, 3}; // 0 = TL, 1 = TR, 2 = BL, 3 = BR (given the bitwise ops in main, vert pos (not tex))
Output main(uint id : SV_VertexID) {
    InstanceData inst = DataBuffer[id / 6]; // Pass over "6" vertices per instance
    uint vertex = triangle_indices[id % 6];

    // Top right quadrant so that quad origin (0,0) is at the bottom left, rather than in the center
    // Allows positioning via bot left at origin and scaling to the texture size
    uint vertex_x = vertex & 0x1;
    uint vertex_y = (vertex >> 1) & 0x1;

    // Build the position of the vertex for the quad
    float2 quad_vertex = float2(vertex_x, vertex_y ^ 0x1); // Invert the y-axis to vertically flip the image to account for texture space TL being (0,0)
    quad_vertex *= inst.tex_dimensions * inst.scale; // Transforms the quad to the same dimensions as the texture within the atlas, then scales it for the instance

    Output output;
    output.tex_coord = float2(inst.tex_coord.x + (vertex_x * inst.tex_dimensions.x), inst.tex_coord.y + (vertex_y * inst.tex_dimensions.y)) / atlas_dimensions;
    output.color = inst.color;
    output.position = mul(projection, float4(quad_vertex + inst.position, 0, 1.0f));

    return output;
}
