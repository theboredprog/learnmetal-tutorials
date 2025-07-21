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

#include <iostream>
#include <cstdlib>

#include <simd/simd.h>
#include "renderer.hpp"

Renderer::Renderer(NSWindow* window)
: m_MetalWindow(window) {}

bool Renderer::Init(int width, int height)
{
    m_MetalDevice = MTL::CreateSystemDefaultDevice();
    if (!m_MetalDevice)
    {
        std::cerr << "[ERROR] Failed to create Metal device." << std::endl;
        return false;
    }
    
    m_MetalLayer = [CAMetalLayer layer];
    if (!m_MetalLayer)
    {
        std::cerr << "[ERROR] Failed to create CAMetalLayer." << std::endl;
        return false;
    }
    
    if (!m_MetalWindow)
    {
        std::cerr << "[ERROR] Failed to get native NSWindow from GLFW." << std::endl;
        return false;
    }
    
    m_MetalLayer.device = (__bridge id<MTLDevice>)m_MetalDevice;
    m_MetalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    m_MetalLayer.drawableSize = CGSizeMake(width, height);
    m_MetalWindow.contentView.wantsLayer = YES;
    m_MetalWindow.contentView.layer = getMetalLayer();
    
    return true;
}

void Renderer::PrepareRenderingData()
{
    simd::float3 triangleVertices[] =
    {
        {-0.5f, -0.5f, 0.0f},
        { 0.5f, -0.5f, 0.0f},
        { 0.0f,  0.5f, 0.0f}
    };

    m_TriangleVertexBuffer = m_MetalDevice->newBuffer(&triangleVertices,
                                                  sizeof(triangleVertices),
                                                      MTL::ResourceStorageModeShared);
    
    m_MetalDefaultLibrary = m_MetalDevice->newDefaultLibrary();
    
    if(!m_MetalDefaultLibrary)
    {
        std::cerr << "[ERROR] Failed to load the Metal default library." << std::endl;
        return;
    }
    
    m_MetalCommandQueue = m_MetalDevice->newCommandQueue();
    
    MTL::Function* vertexShader = m_MetalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
    
    MTL::Function* fragmentShader = m_MetalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));

    if (!vertexShader || !fragmentShader)
    {
        std::cerr << "[ERROR] Shader function not found in library." << std::endl;
        return;
    }
    
    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();

    renderPipelineDescriptor->setLabel(NS::String::string("Triangle Rendering Pipeline", NS::ASCIIStringEncoding));
    
    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);

    if (!renderPipelineDescriptor)
    {
        std::cerr << "[ERROR] Failed to set the Render Pipeline Descriptor." << std::endl;
        return;
    }

    MTL::PixelFormat pixelFormat = (MTL::PixelFormat)m_MetalLayer.pixelFormat;
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);

    NS::Error* error;
    m_MetalRenderPSO = m_MetalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    
    if (!m_MetalRenderPSO)
    {
        std::cerr << "[ERROR] Failed to create Render Pipeline State: " << error->localizedDescription()->utf8String() << std::endl;
        return;
    }

    renderPipelineDescriptor->release();
}

void Renderer::Render()
{
    @autoreleasepool
    {
        m_MetalDrawable = (__bridge_retained CA::MetalDrawable*)[m_MetalLayer nextDrawable];
 
        m_MetalCommandBuffer = m_MetalCommandQueue->commandBuffer();

        MTL::RenderPassDescriptor* renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
        
        MTL::RenderPassColorAttachmentDescriptor* cd = renderPassDescriptor->colorAttachments()->object(0);
        
        cd->setTexture(m_MetalDrawable->texture());
        cd->setLoadAction(MTL::LoadActionClear);
        cd->setClearColor(MTL::ClearColor(41.0f/255.0f, 42.0f/255.0f, 48.0f/255.0f, 1.0));
        cd->setStoreAction(MTL::StoreActionStore);

        MTL::RenderCommandEncoder* renderCommandEncoder = m_MetalCommandBuffer->renderCommandEncoder(renderPassDescriptor);
        
        renderCommandEncoder->setRenderPipelineState(m_MetalRenderPSO);
        renderCommandEncoder->setVertexBuffer(m_TriangleVertexBuffer, 0, 0);
        
        MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
        
        NS::UInteger vertexStart = 0;
        NS::UInteger vertexCount = 3;
        
        renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
        renderCommandEncoder->endEncoding();

        m_MetalCommandBuffer->presentDrawable(m_MetalDrawable);
        m_MetalCommandBuffer->commit();
        m_MetalCommandBuffer->waitUntilCompleted();

        renderPassDescriptor->release();
        
        m_MetalDrawable->release();
        m_MetalDrawable = nullptr;
    }
}

void Renderer::Cleanup()
{
    if (m_MetalRenderPSO)
    {
        m_MetalRenderPSO->release();
        m_MetalRenderPSO = nullptr;
    }
    
    if (m_TriangleVertexBuffer)
    {
        m_TriangleVertexBuffer->release();
        m_TriangleVertexBuffer = nullptr;
    }
    
    if (m_MetalCommandQueue)
    {
        m_MetalCommandQueue->release();
        m_MetalCommandQueue = nullptr;
    }
    
    if (m_MetalDefaultLibrary)
    {
        m_MetalDefaultLibrary->release();
        m_MetalDefaultLibrary = nullptr;
    }
    
    if (m_MetalDevice)
    {
        m_MetalDevice->release();
        m_MetalDevice = nullptr;
    }
}
