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

#include "application.hpp"

#include <iostream>

void glfwErrorCallback(int error, const char* description)
{
    std::cerr << "[GLFW ERROR] (" << error << "): " << description << std::endl;
}

void Application::initWindow()
{
    glfwSetErrorCallback(glfwErrorCallback);
    
    if(!glfwInit())
    {
        std::cerr << "[ERROR] Failed to initialize GLFW." << std::endl;
        glfwTerminate();
        return false;
    }
    
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    
    m_GlfwWindow = glfwCreateWindow(m_Width, m_Height, m_Title, NULL, NULL);
    
    if (!m_GlfwWindow)
    {
        std::cerr << "[ERROR] Failed to create GLFW window." << std::endl;
        glfwTerminate();
        return false;
    }

    int width, height;
    glfwGetFramebufferSize(m_GlfwWindow, &width, &height);

    m_MetalDevice = MTL::CreateSystemDefaultDevice();
    if (!m_MetalDevice)
    {
        std::cerr << "[ERROR] Failed to create Metal device." << std::endl;
        glfwDestroyWindow(m_GlfwWindow);
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    m_MetalWindow = glfwGetCocoaWindow(m_GlfwWindow);

    if (!m_MetalWindow)
    {
        std::cerr << "[ERROR] Failed to get native NSWindow from GLFW." << std::endl;
        glfwDestroyWindow(m_GlfwWindow);
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }
    
    m_MetalLayer = [CAMetalLayer layer];
    if (!m_MetalLayer)
    {
        std::cerr << "[ERROR] Failed to create CAMetalLayer." << std::endl;
        glfwDestroyWindow(m_GlfwWindow);
        glfwTerminate();
        std::exit(EXIT_FAILURE);
    }

    m_MetalLayer.device = (__bridge id<MTLDevice>)m_MetalDevice;
    m_MetalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    m_MetalLayer.drawableSize = CGSizeMake(width, height);
    m_MetalWindow.contentView.layer = m_MetalLayer;
    m_MetalWindow.contentView.wantsLayer = YES;
}

Application::Application(const int width, const int height, const char* title)
: m_Width(width), m_Height(height), m_Title(title) {}

bool Application::Init()
{
    if(!initWindow())
    {
        std::cerr << "[ERROR] Failed to initialize the window." << std::endl;
        glfwDestroyWindow(m_GlfwWindow);
        glfwTerminate();
        return;
    }
}

void Application::Run()
{
    while (!glfwWindowShouldClose(m_GlfwWindow))
    {
        glfwPollEvents();
    }
}

void Application::Cleanup()
{
    m_MetalDevice->release();
    
    glfwTerminate();
}