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
//

#include <metal_stdlib>

using namespace metal;

// Output structure from vertex shader to rasterizer
struct VertexOut
{
    float4 position [[position]]; // Position in clip space (required output)
};

// Vertex shader:
// - Takes vertex ID and pointer to an array of 3D vertex positions
// - Outputs the position as a float4 (with w = 1.0) for rendering
vertex VertexOut vertexShader(uint vertexID [[vertex_id]], constant float3* vertexPositions)
{
    VertexOut out;

    // Load the 3D position from the input array and convert to float4 for GPU
    out.position = float4(vertexPositions[vertexID], 1.0);

    return out;
}

// Fragment shader:
// - Receives interpolated vertex output (position, unused here)
// - Outputs a solid color (mint-like orange)
fragment float4 fragmentShader(VertexOut in [[stage_in]])
{
    float4 mintColor = float4(1.0, 0.5, 0.2, 1.0); // RGBA color

    // Return solid color for every fragment (pixel)
    return mintColor;
}

