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

#include <Metal/Metal.h>
#include <QuartzCore/CAMetalLayer.h>
#include <Metal/Metal.hpp>
#include <QuartzCore/CAMetalLayer.hpp>

#import <AppKit/AppKit.h>

class Renderer
{
private:
    
    MTL::Device* m_MetalDevice;
    
    CAMetalLayer* m_MetalLayer;
    
    NSWindow* m_MetalWindow;
    
    MTL::Buffer* m_TriangleVertexBuffer;
    MTL::Library* m_MetalDefaultLibrary;
    MTL::CommandQueue* m_MetalCommandQueue;
    MTL::RenderPipelineState* m_MetalRenderPSO;
    CA::MetalDrawable* m_MetalDrawable;
    MTL::CommandBuffer* m_MetalCommandBuffer;
    
public:
    
    Renderer(NSWindow* window);
    
    bool Init(int width, int height);
    
    void Render();
    void Cleanup();
    
    void PrepareRenderingData();
    
    inline MTL::Device* getMetalDevice() { return m_MetalDevice; }
    inline CAMetalLayer* getMetalLayer() { return m_MetalLayer; }
};
