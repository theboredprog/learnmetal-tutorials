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

#define GLFW_EXPOSE_NATIVE_COCOA
#import <GLFW/glfw3native.h>

void glfwErrorCallback(int error, const char* description)
{
    std::cerr << "[GLFW ERROR] (" << error << "): " << description << std::endl;
}

bool Application::initWindow()
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
    
    m_Renderer = std::make_unique<Renderer>(glfwGetCocoaWindow(m_GlfwWindow));
    
    if(!m_Renderer->Init(width, height))
    {
        std::cerr << "[ERROR] Failed to initialize the renderer." << std::endl;
        m_Renderer.reset();
        glfwDestroyWindow(m_GlfwWindow);
        glfwTerminate();
        return false;
    }

    m_Renderer->PrepareRenderingData();
    
    return true;
}

Application::Application(const int width, const int height, const char* title)
: m_Width(width), m_Height(height), m_Title(title) {}

void Application::Init()
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
        @autoreleasepool
        {
            m_Renderer->Render();
        }
        glfwPollEvents();
    }
}

void Application::Cleanup()
{
    if (m_Renderer)
    {
        m_Renderer->Cleanup();
    }
    
    glfwTerminate();
}
