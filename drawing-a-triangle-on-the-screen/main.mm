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
#include <simd/simd.h>

#define GLFW_INCLUDE_NONE
#include "../third_party/glfw/include/GLFW/glfw3.h"
#define GLFW_EXPOSE_NATIVE_COCOA
#include "../third_party/glfw/include/GLFW/glfw3native.h"

#include "../third_party/metal-cpp/Metal/Metal.hpp"
#include "../third_party/metal-cpp/QuartzCore/CAMetalLayer.hpp"

const unsigned int SCR_WIDTH = 800;
const unsigned int SCR_HEIGHT = 600;

void glfwErrorCallback(int error, const char* description)
{
    std::cerr << "[GLFW ERROR] (" << error << "): " << description << std::endl;
}

int main()
{
    // GLFW init
    if(!glfwInit())
    {
        std::cerr << "[ERROR] Failed to initialize GLFW." << std::endl;
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }
    
    glfwSetErrorCallback(glfwErrorCallback);
    
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    
    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "LearnMetal", nullptr, nullptr);

    if (!window)
    {
        std::cerr << "[ERROR] Failed to create GLFW window." << std::endl;
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }
    
    int width, height;
    glfwGetFramebufferSize(window, &width, &height);
    
    // Metal Setup
    
    MTL::Device* metalDevice;
    
    CA::MetalLayer* metalLayer;
    
    NSWindow* metalWindow;
    
    MTL::Buffer* triangleVertexBuffer;
    MTL::Library* metalDefaultLibrary;
    MTL::CommandQueue* metalCommandQueue;
    MTL::RenderPipelineState* metalRenderPSO;
    CA::MetalDrawable* metalDrawable;
    MTL::CommandBuffer* metalCommandBuffer;
    
    metalDevice = MTL::CreateSystemDefaultDevice();
    if (!metalDevice)
    {
        std::cerr << "[ERROR] Failed to create Metal device." << std::endl;
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }
    
    metalLayer = CA::MetalLayer::layer();
    if (!metalLayer)
    {
        std::cerr << "[ERROR] Failed to create CAMetalLayer." << std::endl;
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }
    
    metalWindow = glfwGetCocoaWindow(window);

    if (!metalWindow)
    {
        std::cerr << "[ERROR] Failed to get native NSWindow from GLFW." << std::endl;
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }
        
    metalLayer->setDevice(metalDevice);
    metalLayer->setPixelFormat(MTL::PixelFormatBGRA8Unorm);
    metalLayer->setDrawableSize({(CGFloat)width, (CGFloat)height});
    metalWindow.contentView.wantsLayer = YES;
    metalWindow.contentView.layer = (__bridge CALayer *)metalLayer;
    // prepare rendering data
    simd::float3 triangleVertices[] =
    {
        {-0.5f, -0.5f, 0.0f},
        { 0.5f, -0.5f, 0.0f},
        { 0.0f,  0.5f, 0.0f}
    };

    triangleVertexBuffer = metalDevice->newBuffer(&triangleVertices,
                                                  sizeof(triangleVertices),
                                                      MTL::ResourceStorageModeShared);
    
    metalDefaultLibrary = metalDevice->newDefaultLibrary();
    
    if(!metalDefaultLibrary)
    {
        std::cerr << "[ERROR] Failed to load the Metal default library." << std::endl;
        std::exit(EXIT_FAILURE);
    }
    
    metalCommandQueue = metalDevice->newCommandQueue();
    
    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
    
    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));

    if (!vertexShader || !fragmentShader)
    {
        std::cerr << "[ERROR] Shader function not found in library." << std::endl;
        std::exit(EXIT_FAILURE);
    }
    
    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();

    renderPipelineDescriptor->setLabel(NS::String::string("Triangle Rendering Pipeline", NS::ASCIIStringEncoding));
    
    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);

    if (!renderPipelineDescriptor)
    {
        std::cerr << "[ERROR] Failed to set the Render Pipeline Descriptor." << std::endl;
        std::exit(EXIT_FAILURE);
    }

    MTL::PixelFormat pixelFormat = metalLayer->pixelFormat();
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);

    NS::Error* error;
    metalRenderPSO = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    
    if (!metalRenderPSO)
    {
        std::cerr << "[ERROR] Failed to create Render Pipeline State: " << error->localizedDescription()->utf8String() << std::endl;
        std::exit(EXIT_FAILURE);
    }

    renderPipelineDescriptor->release();

    while (!glfwWindowShouldClose(window))
    {
        glfwPollEvents();

        @autoreleasepool
        {
            metalDrawable = metalLayer->nextDrawable();
            
            if (!metalDrawable)
            {
                std::cerr << "[WARNING] m_MetalDrawable is null. Possibly due to invalid layer size or window not drawable." << std::endl;
            }

            metalCommandBuffer = metalCommandQueue->commandBuffer();

            MTL::RenderPassDescriptor* renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
            
            MTL::RenderPassColorAttachmentDescriptor* cd = renderPassDescriptor->colorAttachments()->object(0);
            
            cd->setTexture(metalDrawable->texture());
            cd->setLoadAction(MTL::LoadActionClear);
            cd->setClearColor(MTL::ClearColor(41.0f/255.0f, 42.0f/255.0f, 48.0f/255.0f, 1.0));
            cd->setStoreAction(MTL::StoreActionStore);

            MTL::RenderCommandEncoder* renderCommandEncoder = metalCommandBuffer->renderCommandEncoder(renderPassDescriptor);
            
            renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
            renderCommandEncoder->setVertexBuffer(triangleVertexBuffer, 0, 0);
            
            MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
            
            NS::UInteger vertexStart = 0;
            NS::UInteger vertexCount = 3;
            
            renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
            renderCommandEncoder->endEncoding();

            metalCommandBuffer->presentDrawable(metalDrawable);
            metalCommandBuffer->commit();
            metalCommandBuffer->waitUntilCompleted();

            renderPassDescriptor->release();
        }
    }

    if (metalRenderPSO)
    {
        metalRenderPSO->release();
        metalRenderPSO = nullptr;
    }
    
    if (triangleVertexBuffer)
    {
        triangleVertexBuffer->release();
        triangleVertexBuffer = nullptr;
    }
    
    if (metalCommandQueue)
    {
        metalCommandQueue->release();
        metalCommandQueue = nullptr;
    }
    
    if (metalDefaultLibrary)
    {
        metalDefaultLibrary->release();
        metalDefaultLibrary = nullptr;
    }
    
    if (metalDevice)
    {
        metalDevice->release();
        metalDevice = nullptr;
    }
    
    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}