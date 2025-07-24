// MIT License
//
// Copyright (c) 2025 Gabriele Vierti
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <metal_stdlib>
using namespace metal;

// Input structure for vertex shader, describing vertex attributes
struct VertexIn {
    float3 position [[attribute(0)]];  // 3D position from vertex buffer attribute 0
    float2 uv       [[attribute(1)]];  // Texture coordinates (UV) from vertex buffer attribute 1
};

// Output structure from vertex shader to fragment shader
struct VertexOut {
    float4 position [[position]];  // Position in clip space (required output for rasterizer)
    float2 uv;                     // Pass-through texture coordinates to fragment shader
};

// Vertex shader function:
// - Receives vertex ID and a pointer to vertex array (buffer 0)
// - Outputs transformed position and UV coordinates
vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                              const device VertexIn* vertices [[buffer(0)]]) {
    VertexOut out;

    // Convert vertex position to a 4D vector (x, y, z, w=1.0) for clip space
    out.position = float4(vertices[vertexID].position, 1.0);

    // Pass UV coordinates to fragment shader unchanged
    out.uv = vertices[vertexID].uv;

    return out;
}

// Fragment shader function:
// - Receives interpolated vertex output (UVs)
// - Samples texture at given UV coordinates using a sampler
// - Returns sampled color as output pixel color
fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> tex [[texture(0)]]) {
    // Define a sampler with clamp-to-edge addressing and linear filtering
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    // Sample the texture at the interpolated UV coordinates
    return tex.sample(s, in.uv);
}
