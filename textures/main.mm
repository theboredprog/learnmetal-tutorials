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

// Vertex structure: position in 3D space + texture coordinates (UV)
struct Vertex {
    simd::float3 position;
    simd::float2 uv;
};

// GLFW error callback for debugging GLFW errors
void glfwErrorCallback(int error, const char* description) {
    std::cerr << "[GLFW ERROR] (" << error << "): " << description << std::endl;
}

// Function to load an image from disk into a Metal texture
MTL::Texture* LoadTexture(MTL::Device* device, const char* filepath) {
    int width, height, channels;
    stbi_uc* pixels = stbi_load(filepath, &width, &height, &channels, STBI_rgb_alpha);
    if (!pixels) {
        std::cerr << "[ERROR] Failed to load texture: " << filepath << std::endl;
        return nullptr;
    }

    // Describe the texture format and properties
    MTL::TextureDescriptor* desc = MTL::TextureDescriptor::texture2DDescriptor(
        MTL::PixelFormatRGBA8Unorm, width, height, false);
    desc->setStorageMode(MTL::StorageModeManaged);
    desc->setUsage(MTL::TextureUsageShaderRead);

    // Create Metal texture object
    MTL::Texture* texture = device->newTexture(desc);
    if (!texture) {
        std::cerr << "[ERROR] Failed to create Metal texture." << std::endl;
        stbi_image_free(pixels);
        return nullptr;
    }

    // Upload pixel data to the GPU texture
    texture->replaceRegion(
        MTL::Region(0, 0, width, height),
        0,
        pixels,
        width * 4
    );

    // Cleanup CPU pixel data and descriptor
    stbi_image_free(pixels);
    desc->release();

    return texture;
}

int main() {
    // --- Step 1: Initialize GLFW for window creation ---
    if (!glfwInit()) {
        std::cerr << "[ERROR] Failed to initialize GLFW." << std::endl;
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }
    glfwSetErrorCallback(glfwErrorCallback);
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API); // No OpenGL context

    // Create a window with GLFW
    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Textures", nullptr, nullptr);
    if (!window) {
        std::cerr << "[ERROR] Failed to create GLFW window." << std::endl;
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    // Get actual framebuffer size (important for Retina/HiDPI)
    int width, height;
    glfwGetFramebufferSize(window, &width, &height);

    // --- Step 2: Create Metal Device and Layer ---
    MTL::Device* metalDevice = MTL::CreateSystemDefaultDevice();
    if (!metalDevice) {
        std::cerr << "[ERROR] Failed to create Metal device." << std::endl;
        glfwDestroyWindow(window);
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    // Create a Metal layer and attach it to the GLFW window's content view
    CA::MetalLayer* metalLayer = CA::MetalLayer::layer();
    NSWindow* metalWindow = glfwGetCocoaWindow(window);
    metalLayer->setDevice(metalDevice);
    metalLayer->setPixelFormat(MTL::PixelFormatBGRA8Unorm);
    metalLayer->setDrawableSize({(CGFloat)width, (CGFloat)height});
    metalWindow.contentView.wantsLayer = YES;
    metalWindow.contentView.layer = (__bridge CALayer*)metalLayer;

    // --- Step 3: Define vertex data for a quad (2D square) ---
    Vertex quadVertices[] = {
        {{-0.5f, -0.5f, 0.0f}, {0.0f, 1.0f}}, // bottom-left
        {{ 0.5f, -0.5f, 0.0f}, {1.0f, 1.0f}}, // bottom-right
        {{-0.5f,  0.5f, 0.0f}, {0.0f, 0.0f}}, // top-left
        {{ 0.5f,  0.5f, 0.0f}, {1.0f, 0.0f}}, // top-right
    };

    // Upload vertices to GPU in a buffer
    MTL::Buffer* quadVertexBuffer = metalDevice->newBuffer(
        quadVertices, sizeof(quadVertices), MTL::ResourceStorageModeShared);
    if (!quadVertexBuffer) {
        std::cerr << "[ERROR] Failed to create vertex buffer." << std::endl;
        metalDevice->release();
        glfwDestroyWindow(window);
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    // --- Step 4: Load Metal shaders (vertex and fragment) ---
    MTL::Library* metalDefaultLibrary = metalDevice->newDefaultLibrary();
    if (!metalDefaultLibrary) {
        std::cerr << "[ERROR] Failed to load default Metal library. Make sure your .metal files are compiled and included." << std::endl;
        quadVertexBuffer->release();
        metalDevice->release();
        glfwDestroyWindow(window);
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    // Get vertex shader function from the library
    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
    if (!vertexShader) {
        std::cerr << "[ERROR] Failed to find vertex shader function 'vertexShader' in the Metal library." << std::endl;
        metalDefaultLibrary->release();
        quadVertexBuffer->release();
        metalDevice->release();
        glfwDestroyWindow(window);
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    // Get fragment shader function from the library
    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));
    if (!fragmentShader) {
        std::cerr << "[ERROR] Failed to find fragment shader function 'fragmentShader' in the Metal library." << std::endl;
        vertexShader->release();
        metalDefaultLibrary->release();
        quadVertexBuffer->release();
        metalDevice->release();
        glfwDestroyWindow(window);
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    // --- Step 5: Create a Render Pipeline ---
    // Connect shaders and define output pixel format
    MTL::RenderPipelineDescriptor* pipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    pipelineDescriptor->setVertexFunction(vertexShader);
    pipelineDescriptor->setFragmentFunction(fragmentShader);
    pipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(MTL::PixelFormatBGRA8Unorm);

    NS::Error* error = nullptr;
    MTL::RenderPipelineState* renderPipeline = metalDevice->newRenderPipelineState(pipelineDescriptor, &error);
    if (!renderPipeline) {
        std::cerr << "[ERROR] Pipeline creation failed: " << error->localizedDescription()->utf8String() << std::endl;
        pipelineDescriptor->release();
        fragmentShader->release();
        vertexShader->release();
        metalDefaultLibrary->release();
        quadVertexBuffer->release();
        metalDevice->release();
        glfwDestroyWindow(window);
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }
    pipelineDescriptor->release();

    // Release shaders, no longer needed individually
    fragmentShader->release();
    vertexShader->release();
    metalDefaultLibrary->release();

    // --- Step 6: Create command queue to send commands to GPU ---
    MTL::CommandQueue* commandQueue = metalDevice->newCommandQueue();
    if (!commandQueue) {
        std::cerr << "[ERROR] Failed to create command queue." << std::endl;
        renderPipeline->release();
        quadVertexBuffer->release();
        metalDevice->release();
        glfwDestroyWindow(window);
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    // --- Step 7: Load texture from disk ---
    MTL::Texture* texture = LoadTexture(metalDevice, "assets/texture.png");
    if (!texture) {
        std::cerr << "[ERROR] Texture loading failed." << std::endl;
        commandQueue->release();
        renderPipeline->release();
        quadVertexBuffer->release();
        metalDevice->release();
        glfwDestroyWindow(window);
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    // --- Step 8: Main render loop ---
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        @autoreleasepool
        {
            // Acquire next drawable surface to render to
            CA::MetalDrawable* drawable = metalLayer->nextDrawable();
            if (!drawable) continue;

            // Create a render pass descriptor describing the render target and clear color
            MTL::RenderPassDescriptor* passDesc = MTL::RenderPassDescriptor::alloc()->init();
            auto* color = passDesc->colorAttachments()->object(0);
            color->setTexture(drawable->texture());
            color->setLoadAction(MTL::LoadActionClear);
            color->setClearColor(MTL::ClearColor(0.15f, 0.15f, 0.2f, 1.0f)); // Background color
            color->setStoreAction(MTL::StoreActionStore);

            // Create command buffer and encoder to issue draw commands
            MTL::CommandBuffer* cmdBuffer = commandQueue->commandBuffer();
            MTL::RenderCommandEncoder* encoder = cmdBuffer->renderCommandEncoder(passDesc);

            // Set pipeline state, vertex buffer, and fragment texture
            encoder->setRenderPipelineState(renderPipeline);
            encoder->setVertexBuffer(quadVertexBuffer, 0, 0);
            encoder->setFragmentTexture(texture, 0);

            // Draw 4 vertices as a triangle strip (2 triangles forming a quad)
            NS::UInteger vertexStart = 0;
            NS::UInteger vertexCount = 4;
            encoder->drawPrimitives(MTL::PrimitiveTypeTriangleStrip, vertexStart, vertexCount);

            // Finalize encoding and submit commands
            encoder->endEncoding();
            cmdBuffer->presentDrawable(drawable);
            cmdBuffer->commit();
            cmdBuffer->waitUntilCompleted();

            passDesc->release();
        }
    }

    // --- Step 9: Cleanup all allocated resources ---
    if (texture) texture->release();
    if (commandQueue) commandQueue->release();
    if (renderPipeline) renderPipeline->release();
    if (quadVertexBuffer) quadVertexBuffer->release();
    if (metalDevice) metalDevice->release();

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}

