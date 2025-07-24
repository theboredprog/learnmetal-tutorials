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

// Prevent GLFW from including OpenGL headers automatically
#define GLFW_INCLUDE_NONE
#include "path to glfw3.h"  // Replace with actual glfw3.h path

// Window dimensions
const unsigned int SCR_WIDTH = 800;
const unsigned int SCR_HEIGHT = 600;

// GLFW error callback function to print errors
void glfwErrorCallback(int error, const char* description)
{
    std::cerr << "[GLFW ERROR] (" << error << "): " << description << std::endl;
}

int main()
{
    // Initialize GLFW library
    if(!glfwInit())
    {
        std::cerr << "[ERROR] Failed to initialize GLFW." << std::endl;
        glfwTerminate();          // Cleanup GLFW before exit
        std::exit(EXIT_FAILURE);  // Exit program with failure code
    }
    
    // Set the error callback function to handle GLFW errors
    glfwSetErrorCallback(glfwErrorCallback);
    
    // Tell GLFW not to create an OpenGL context (for Vulkan, Metal, etc.)
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    
    // Create a GLFW window with given width, height and title
    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "My Window", nullptr, nullptr);

    // Check if window creation failed
    if (!window)
    {
        std::cerr << "[ERROR] Failed to create GLFW window." << std::endl;
        glfwTerminate();          // Cleanup GLFW before exit
        std::exit(EXIT_FAILURE);  // Exit program with failure code
    }
    
    // Get actual framebuffer size (important for high-DPI displays)
    int width, height;
    glfwGetFramebufferSize(window, &width, &height);
    
    // Main event loop: run until the window is closed
    while (!glfwWindowShouldClose(window))
    {
        glfwPollEvents(); // Process pending window events
    }
    
    // Cleanup and close the window
    glfwDestroyWindow(window);
    glfwTerminate();  // Terminate GLFW
    
    return 0; // Exit program successfully
}
