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

#define STB_IMAGE_IMPLEMENTATION
#include "path to /stbi/stbi-image.h"

#define GLFW_INCLUDE_NONE
#include "path to glfw3.h"
#define GLFW_EXPOSE_NATIVE_COCOA
#include "path to glfw3native.h"

#include ".path to metal-cpp/Metal/Metal.hpp"
#include "path to metal-cpp/QuartzCore/CAMetalLayer.hpp"

const unsigned int SCR_WIDTH = 800;
const unsigned int SCR_HEIGHT = 600;

struct Vertex {
    simd::float3 position;
    simd::float2 uv;
};

void glfwErrorCallback(int error, const char* description) {
    std::cerr << "[GLFW ERROR] (" << error << "): " << description << std::endl;
}

MTL::Texture* LoadTexture(MTL::Device* device, const char* filepath) {
    int width, height, channels;
    stbi_uc* pixels = stbi_load(filepath, &width, &height, &channels, STBI_rgb_alpha);
    if (!pixels) {
        std::cerr << "[ERROR] Failed to load texture: " << filepath << std::endl;
        return nullptr;
    }

    MTL::TextureDescriptor* desc = MTL::TextureDescriptor::texture2DDescriptor(
        MTL::PixelFormatRGBA8Unorm, width, height, false);
    desc->setStorageMode(MTL::StorageModeManaged);
    desc->setUsage(MTL::TextureUsageShaderRead);

    MTL::Texture* texture = device->newTexture(desc);
    texture->replaceRegion(
        MTL::Region(0, 0, width, height),
        0,
        pixels,
        width * 4
    );

    stbi_image_free(pixels);
    return texture;
}

int main() {
    if (!glfwInit()) {
        std::cerr << "[ERROR] Failed to initialize GLFW." << std::endl;
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    glfwSetErrorCallback(glfwErrorCallback);
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Textures", nullptr, nullptr);

    if (!window) {
        std::cerr << "[ERROR] Failed to create GLFW window." << std::endl;
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    int width, height;
    glfwGetFramebufferSize(window, &width, &height);

    MTL::Device* metalDevice = MTL::CreateSystemDefaultDevice();
    if (!metalDevice) {
        std::cerr << "[ERROR] Failed to create Metal device." << std::endl;
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    CA::MetalLayer* metalLayer = CA::MetalLayer::layer();
    NSWindow* metalWindow = glfwGetCocoaWindow(window);

    metalLayer->setDevice(metalDevice);
    metalLayer->setPixelFormat(MTL::PixelFormatBGRA8Unorm);
    metalLayer->setDrawableSize({(CGFloat)width, (CGFloat)height});
    metalWindow.contentView.wantsLayer = YES;
    metalWindow.contentView.layer = (__bridge CALayer*)metalLayer;

    // Quad vertices
    Vertex quadVertices[] = {
        {{-0.5f, -0.5f, 0.0f}, {0.0f, 1.0f}},
        {{ 0.5f, -0.5f, 0.0f}, {1.0f, 1.0f}},
        {{-0.5f,  0.5f, 0.0f}, {0.0f, 0.0f}},
        {{ 0.5f,  0.5f, 0.0f}, {1.0f, 0.0f}},
    };

    MTL::Buffer* quadVertexBuffer = metalDevice->newBuffer(
        quadVertices, sizeof(quadVertices), MTL::ResourceStorageModeShared);

    MTL::Library* metalDefaultLibrary = metalDevice->newDefaultLibrary();
    if (!metalDefaultLibrary) {
        std::cerr << "[ERROR] Failed to load default Metal library." << std::endl;
        std::exit(EXIT_FAILURE);
    }

    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));

    MTL::RenderPipelineDescriptor* pipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    pipelineDescriptor->setVertexFunction(vertexShader);
    pipelineDescriptor->setFragmentFunction(fragmentShader);
    pipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(MTL::PixelFormatBGRA8Unorm);

    NS::Error* error = nullptr;
    MTL::RenderPipelineState* renderPipeline = metalDevice->newRenderPipelineState(pipelineDescriptor, &error);
    if (!renderPipeline) {
        std::cerr << "[ERROR] Pipeline creation failed: " << error->localizedDescription()->utf8String() << std::endl;
        std::exit(EXIT_FAILURE);
    }
    pipelineDescriptor->release();

    MTL::CommandQueue* commandQueue = metalDevice->newCommandQueue();

    MTL::Texture* texture = LoadTexture(metalDevice, "pathtoyourtexture.png");
    if (!texture) std::exit(EXIT_FAILURE);

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        @autoreleasepool {
            CA::MetalDrawable* drawable = metalLayer->nextDrawable();
            if (!drawable) continue;

            MTL::RenderPassDescriptor* passDesc = MTL::RenderPassDescriptor::alloc()->init();
            auto* color = passDesc->colorAttachments()->object(0);
            color->setTexture(drawable->texture());
            color->setLoadAction(MTL::LoadActionClear);
            color->setClearColor(MTL::ClearColor(0.15f, 0.15f, 0.2f, 1.0f));
            color->setStoreAction(MTL::StoreActionStore);

            MTL::CommandBuffer* cmdBuffer = commandQueue->commandBuffer();
            MTL::RenderCommandEncoder* encoder = cmdBuffer->renderCommandEncoder(passDesc);

            encoder->setRenderPipelineState(renderPipeline);
            encoder->setVertexBuffer(quadVertexBuffer, 0, 0);
            encoder->setFragmentTexture(texture, 0);
            
            NS::UInteger vertexStart = 0;
            NS::UInteger vertexCount = 4;
            
            encoder->drawPrimitives(MTL::PrimitiveTypeTriangleStrip, vertexStart, vertexCount);
            
            encoder->endEncoding();

            cmdBuffer->presentDrawable(drawable);
            cmdBuffer->commit();
            cmdBuffer->waitUntilCompleted();

            passDesc->release();
        }
    }

    if (renderPipeline) renderPipeline->release();
    if (quadVertexBuffer) quadVertexBuffer->release();
    if (commandQueue) commandQueue->release();
    if (metalDefaultLibrary) metalDefaultLibrary->release();
    if (texture) texture->release();
    if (metalDevice) metalDevice->release();

    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}
