#include "FaceGpuRenderer.h"

#include <EGL/eglext.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <thread>
#include <vector>

#ifndef EGL_OPENGL_ES3_BIT_KHR
#define EGL_OPENGL_ES3_BIT_KHR 0x0040
#endif

namespace {
constexpr const char *VERTEX_SHADER = R"(#version 300 es
precision highp float;
layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in float aHeat;

uniform vec3 uPose;
uniform vec3 uView;
uniform float uZoom;
uniform float uAspect;

out vec3 vNormal;
out float vHeat;

vec3 rotateEuler(vec3 value, vec3 angles) {
    float rx = radians(angles.x);
    float ry = radians(angles.y);
    float rz = radians(angles.z);
    float sx = sin(rx), cx = cos(rx);
    float sy = sin(ry), cy = cos(ry);
    float sz = sin(rz), cz = cos(rz);

    value = vec3(value.x, value.y * cx - value.z * sx, value.y * sx + value.z * cx);
    value = vec3(value.x * cy + value.z * sy, value.y, -value.x * sy + value.z * cy);
    value = vec3(value.x * cz - value.y * sz, value.x * sz + value.y * cz, value.z);
    return value;
}

void main() {
    vec3 p = rotateEuler(rotateEuler(aPosition, uPose), uView);
    vec3 n = rotateEuler(rotateEuler(aNormal, uPose), uView);
    vNormal = normalize(n);
    vHeat = aHeat;
    float safeAspect = max(uAspect, 0.55);
    gl_Position = vec4((p.x / safeAspect) * 1.28 * uZoom, p.y * 1.28 * uZoom, p.z * 0.52, 1.0);
}
)";

constexpr const char *FRAGMENT_SHADER = R"(#version 300 es
precision highp float;
in vec3 vNormal;
in float vHeat;
uniform int uMode;
out vec4 outColor;

vec3 heatColor(float value) {
    float t = clamp(value, 0.0, 1.0);
    if (t < 0.25) return mix(vec3(0.08, 0.20, 0.82), vec3(0.02, 0.78, 0.92), t * 4.0);
    if (t < 0.50) return mix(vec3(0.02, 0.78, 0.92), vec3(0.22, 0.82, 0.42), (t - 0.25) * 4.0);
    if (t < 0.75) return mix(vec3(0.22, 0.82, 0.42), vec3(0.98, 0.84, 0.16), (t - 0.50) * 4.0);
    return mix(vec3(0.98, 0.84, 0.16), vec3(0.94, 0.20, 0.16), (t - 0.75) * 4.0);
}

void main() {
    if (uMode == 0) {
        outColor = vec4(0.30, 0.84, 0.91, 1.0);
        return;
    }
    if (uMode == 2) {
        outColor = vec4(heatColor(vHeat), 1.0);
        return;
    }
    vec3 normal = normalize(vNormal);
    vec3 lightDir = normalize(vec3(-0.35, 0.55, 1.0));
    float diffuse = max(dot(normal, lightDir), 0.0);
    float rim = pow(1.0 - max(dot(normal, vec3(0.0, 0.0, 1.0)), 0.0), 2.0);
    vec3 base = vec3(0.16, 0.43, 0.54);
    vec3 color = base * (0.24 + diffuse * 0.76) + vec3(0.18, 0.42, 0.50) * rim * 0.22;
    outColor = vec4(color, 1.0);
}
)";

float Dot3(const float *a, const float *b)
{
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}
}

FaceGpuRenderer::FaceGpuRenderer(uint64_t surfaceId) : surfaceId_(surfaceId)
{
}

FaceGpuRenderer::~FaceGpuRenderer()
{
    Stop();
}

void FaceGpuRenderer::Start()
{
    bool expected = false;
    if (!running_.compare_exchange_strong(expected, true)) {
        return;
    }
    renderThread_ = std::thread(&FaceGpuRenderer::RenderLoop, this);
}

void FaceGpuRenderer::Stop()
{
    running_.store(false);
    if (renderThread_.joinable()) {
        renderThread_.join();
    }
}

void FaceGpuRenderer::Resize(int32_t width, int32_t height)
{
    std::lock_guard<std::mutex> lock(dataMutex_);
    requestedWidth_ = std::max(1, width);
    requestedHeight_ = std::max(1, height);
}

void FaceGpuRenderer::UpdateMesh(const float *vertices, size_t vertexFloatCount,
                                 const uint32_t *triangles, size_t triangleIndexCount,
                                 const uint32_t *edges, size_t edgeIndexCount,
                                 const float *deformation, size_t deformationCount,
                                 float pitch, float yaw, float roll,
                                 uint64_t topologyRevision, int32_t mode)
{
    std::lock_guard<std::mutex> lock(dataMutex_);
    if (vertices != nullptr && vertexFloatCount > 0) {
        vertices_.assign(vertices, vertices + vertexFloatCount);
    } else {
        vertices_.clear();
    }
    if (deformation != nullptr && deformationCount > 0) {
        deformation_.assign(deformation, deformation + deformationCount);
    } else {
        deformation_.clear();
    }

    if (topologyRevision_ != topologyRevision || triangles_.empty() || edges_.empty()) {
        if (triangles != nullptr && triangleIndexCount > 0) {
            triangles_.assign(triangles, triangles + triangleIndexCount);
        } else {
            triangles_.clear();
        }
        if (edges != nullptr && edgeIndexCount > 0) {
            edges_.assign(edges, edges + edgeIndexCount);
        } else {
            edges_.clear();
        }
        topologyRevision_ = topologyRevision;
    }

    pitch_ = pitch;
    yaw_ = yaw;
    roll_ = roll;
    mode_ = std::clamp(mode, 0, 2);
    hasMesh_ = vertices_.size() >= 9 && triangles_.size() >= 3;
    ++dataRevision_;
}

void FaceGpuRenderer::SetViewTransform(float pitch, float yaw, float zoom)
{
    std::lock_guard<std::mutex> lock(dataMutex_);
    viewPitch_ = std::clamp(pitch, -78.0f, 78.0f);
    viewYaw_ = std::clamp(yaw, -180.0f, 180.0f);
    viewZoom_ = std::clamp(zoom, 0.65f, 2.8f);
}

void FaceGpuRenderer::ClearMesh()
{
    std::lock_guard<std::mutex> lock(dataMutex_);
    vertices_.clear();
    deformation_.clear();
    triangles_.clear();
    edges_.clear();
    topologyRevision_ = UINT64_MAX;
    hasMesh_ = false;
    ++dataRevision_;
}

void FaceGpuRenderer::RenderLoop()
{
    if (!InitializeEgl()) {
        running_.store(false);
        ReleaseEgl();
        return;
    }

    auto nextFrame = std::chrono::steady_clock::now();
    constexpr auto frameInterval = std::chrono::milliseconds(33);
    while (running_.load()) {
        RenderFrame();
        nextFrame += frameInterval;
        auto now = std::chrono::steady_clock::now();
        if (nextFrame < now - std::chrono::milliseconds(100)) {
            nextFrame = now;
        }
        std::this_thread::sleep_until(nextFrame);
    }

    ReleaseGl();
    ReleaseEgl();
}

bool FaceGpuRenderer::InitializeEgl()
{
    if (OH_NativeWindow_CreateNativeWindowFromSurfaceId(surfaceId_, &nativeWindow_) != 0 ||
        nativeWindow_ == nullptr) {
        return false;
    }

    display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (display_ == EGL_NO_DISPLAY || eglInitialize(display_, nullptr, nullptr) != EGL_TRUE) {
        return false;
    }

    const EGLint configAttributes[] = {
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT_KHR,
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_DEPTH_SIZE, 16,
        EGL_NONE
    };
    EGLint configCount = 0;
    if (eglChooseConfig(display_, configAttributes, &config_, 1, &configCount) != EGL_TRUE ||
        configCount < 1) {
        return false;
    }

    surface_ = eglCreateWindowSurface(display_, config_,
        reinterpret_cast<EGLNativeWindowType>(nativeWindow_), nullptr);
    if (surface_ == EGL_NO_SURFACE) {
        return false;
    }

    const EGLint contextAttributes[] = {
        EGL_CONTEXT_CLIENT_VERSION, 3,
        EGL_NONE
    };
    context_ = eglCreateContext(display_, config_, EGL_NO_CONTEXT, contextAttributes);
    if (context_ == EGL_NO_CONTEXT ||
        eglMakeCurrent(display_, surface_, surface_, context_) != EGL_TRUE) {
        return false;
    }

    eglQuerySurface(display_, surface_, EGL_WIDTH, &surfaceWidth_);
    eglQuerySurface(display_, surface_, EGL_HEIGHT, &surfaceHeight_);
    glViewport(0, 0, surfaceWidth_, surfaceHeight_);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glDisable(GL_CULL_FACE);
    return InitializeGl();
}

GLuint FaceGpuRenderer::CompileShader(GLenum type, const char *source)
{
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);
    GLint compiled = GL_FALSE;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if (compiled != GL_TRUE) {
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

GLuint FaceGpuRenderer::CreateProgram()
{
    GLuint vertexShader = CompileShader(GL_VERTEX_SHADER, VERTEX_SHADER);
    GLuint fragmentShader = CompileShader(GL_FRAGMENT_SHADER, FRAGMENT_SHADER);
    if (vertexShader == 0 || fragmentShader == 0) {
        if (vertexShader != 0) glDeleteShader(vertexShader);
        if (fragmentShader != 0) glDeleteShader(fragmentShader);
        return 0;
    }

    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    GLint linked = GL_FALSE;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (linked != GL_TRUE) {
        glDeleteProgram(program);
        return 0;
    }
    return program;
}

bool FaceGpuRenderer::InitializeGl()
{
    program_ = CreateProgram();
    if (program_ == 0) {
        return false;
    }
    poseLocation_ = glGetUniformLocation(program_, "uPose");
    viewLocation_ = glGetUniformLocation(program_, "uView");
    zoomLocation_ = glGetUniformLocation(program_, "uZoom");
    aspectLocation_ = glGetUniformLocation(program_, "uAspect");
    modeLocation_ = glGetUniformLocation(program_, "uMode");

    glGenVertexArrays(1, &vao_);
    glGenBuffers(1, &vertexBuffer_);
    glGenBuffers(1, &triangleBuffer_);
    glGenBuffers(1, &edgeBuffer_);

    glBindVertexArray(vao_);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer_);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(GpuVertex),
                          reinterpret_cast<void *>(offsetof(GpuVertex, position)));
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(GpuVertex),
                          reinterpret_cast<void *>(offsetof(GpuVertex, normal)));
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 1, GL_FLOAT, GL_FALSE, sizeof(GpuVertex),
                          reinterpret_cast<void *>(offsetof(GpuVertex, heat)));
    glBindVertexArray(0);
    return true;
}

void FaceGpuRenderer::UploadMeshLocked()
{
    const size_t vertexCount = vertices_.size() / 3;
    if (vertexCount < 3) {
        triangleIndexCount_ = 0;
        edgeIndexCount_ = 0;
        uploadedRevision_ = dataRevision_;
        return;
    }

    std::vector<float> normals(vertexCount * 3, 0.0f);
    for (size_t i = 0; i + 2 < triangles_.size(); i += 3) {
        const uint32_t ia = triangles_[i];
        const uint32_t ib = triangles_[i + 1];
        const uint32_t ic = triangles_[i + 2];
        if (ia >= vertexCount || ib >= vertexCount || ic >= vertexCount) {
            continue;
        }
        const float ab[3] = {
            vertices_[ib * 3] - vertices_[ia * 3],
            vertices_[ib * 3 + 1] - vertices_[ia * 3 + 1],
            vertices_[ib * 3 + 2] - vertices_[ia * 3 + 2]
        };
        const float ac[3] = {
            vertices_[ic * 3] - vertices_[ia * 3],
            vertices_[ic * 3 + 1] - vertices_[ia * 3 + 1],
            vertices_[ic * 3 + 2] - vertices_[ia * 3 + 2]
        };
        const float normal[3] = {
            ab[1] * ac[2] - ab[2] * ac[1],
            ab[2] * ac[0] - ab[0] * ac[2],
            ab[0] * ac[1] - ab[1] * ac[0]
        };
        for (uint32_t index : {ia, ib, ic}) {
            normals[index * 3] += normal[0];
            normals[index * 3 + 1] += normal[1];
            normals[index * 3 + 2] += normal[2];
        }
    }

    float minBounds[3] = {vertices_[0], vertices_[1], vertices_[2]};
    float maxBounds[3] = {vertices_[0], vertices_[1], vertices_[2]};
    for (size_t i = 0; i < vertexCount; ++i) {
        for (int axis = 0; axis < 3; ++axis) {
            minBounds[axis] = std::min(minBounds[axis], vertices_[i * 3 + axis]);
            maxBounds[axis] = std::max(maxBounds[axis], vertices_[i * 3 + axis]);
        }
    }
    const float center[3] = {
        (minBounds[0] + maxBounds[0]) * 0.5f,
        (minBounds[1] + maxBounds[1]) * 0.5f,
        (minBounds[2] + maxBounds[2]) * 0.5f
    };
    const float extent = std::max({maxBounds[0] - minBounds[0],
                                   maxBounds[1] - minBounds[1],
                                   maxBounds[2] - minBounds[2], 0.0001f});
    const float scale = 1.72f / extent;

    float maxHeat = 0.0f;
    for (float value : deformation_) {
        maxHeat = std::max(maxHeat, value);
    }
    const float heatScale = maxHeat > 0.0000001f ? maxHeat : 1.0f;

    std::vector<GpuVertex> gpuVertices(vertexCount);
    for (size_t i = 0; i < vertexCount; ++i) {
        GpuVertex &target = gpuVertices[i];
        target.position[0] = (vertices_[i * 3] - center[0]) * scale;
        target.position[1] = (vertices_[i * 3 + 1] - center[1]) * scale;
        target.position[2] = (vertices_[i * 3 + 2] - center[2]) * scale;

        float normal[3] = {normals[i * 3], normals[i * 3 + 1], normals[i * 3 + 2]};
        const float length = std::sqrt(Dot3(normal, normal));
        if (length > 0.000001f) {
            target.normal[0] = normal[0] / length;
            target.normal[1] = normal[1] / length;
            target.normal[2] = normal[2] / length;
        } else {
            target.normal[0] = 0.0f;
            target.normal[1] = 0.0f;
            target.normal[2] = 1.0f;
        }
        const float displacement = i < deformation_.size() ? deformation_[i] : 0.0f;
        target.heat = std::clamp(displacement / heatScale, 0.0f, 1.0f);
    }

    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer_);
    glBufferData(GL_ARRAY_BUFFER, gpuVertices.size() * sizeof(GpuVertex),
                 gpuVertices.data(), GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, triangleBuffer_);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, triangles_.size() * sizeof(uint32_t),
                 triangles_.data(), GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, edgeBuffer_);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, edges_.size() * sizeof(uint32_t),
                 edges_.data(), GL_DYNAMIC_DRAW);

    triangleIndexCount_ = static_cast<GLsizei>(triangles_.size());
    edgeIndexCount_ = static_cast<GLsizei>(edges_.size());
    uploadedRevision_ = dataRevision_;
}

void FaceGpuRenderer::RenderFrame()
{
    if (eglMakeCurrent(display_, surface_, surface_, context_) != EGL_TRUE) {
        return;
    }

    int32_t mode = 0;
    float pitch = 0.0f;
    float yaw = 0.0f;
    float roll = 0.0f;
    float viewPitch = 0.0f;
    float viewYaw = 0.0f;
    float viewZoom = 1.0f;
    bool hasMesh = false;
    int32_t width = surfaceWidth_;
    int32_t height = surfaceHeight_;

    {
        std::lock_guard<std::mutex> lock(dataMutex_);
        if (requestedWidth_ > 0 && requestedHeight_ > 0) {
            width = requestedWidth_;
            height = requestedHeight_;
        }
        if (uploadedRevision_ != dataRevision_) {
            UploadMeshLocked();
        }
        mode = mode_;
        pitch = pitch_;
        yaw = yaw_;
        roll = roll_;
        viewPitch = viewPitch_;
        viewYaw = viewYaw_;
        viewZoom = viewZoom_;
        hasMesh = hasMesh_;
    }

    if (width <= 0 || height <= 0) {
        return;
    }
    glViewport(0, 0, width, height);
    glClearColor(0.035f, 0.065f, 0.105f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    if (hasMesh && program_ != 0) {
        glUseProgram(program_);
        glUniform3f(poseLocation_, pitch, yaw, roll);
        glUniform3f(viewLocation_, viewPitch, viewYaw, 0.0f);
        glUniform1f(zoomLocation_, viewZoom);
        glUniform1f(aspectLocation_, static_cast<float>(width) / static_cast<float>(height));
        glUniform1i(modeLocation_, mode);
        glBindVertexArray(vao_);
        if (mode == 0 && edgeIndexCount_ > 0) {
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, edgeBuffer_);
            glLineWidth(1.0f);
            glDrawElements(GL_LINES, edgeIndexCount_, GL_UNSIGNED_INT, nullptr);
        } else if (triangleIndexCount_ > 0) {
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, triangleBuffer_);
            glDrawElements(GL_TRIANGLES, triangleIndexCount_, GL_UNSIGNED_INT, nullptr);
        }
        glBindVertexArray(0);
    }

    eglSwapBuffers(display_, surface_);
}

void FaceGpuRenderer::ReleaseGl()
{
    if (display_ != EGL_NO_DISPLAY && context_ != EGL_NO_CONTEXT) {
        eglMakeCurrent(display_, surface_, surface_, context_);
        if (edgeBuffer_ != 0) glDeleteBuffers(1, &edgeBuffer_);
        if (triangleBuffer_ != 0) glDeleteBuffers(1, &triangleBuffer_);
        if (vertexBuffer_ != 0) glDeleteBuffers(1, &vertexBuffer_);
        if (vao_ != 0) glDeleteVertexArrays(1, &vao_);
        if (program_ != 0) glDeleteProgram(program_);
    }
    edgeBuffer_ = 0;
    triangleBuffer_ = 0;
    vertexBuffer_ = 0;
    vao_ = 0;
    program_ = 0;
}

void FaceGpuRenderer::ReleaseEgl()
{
    if (display_ != EGL_NO_DISPLAY) {
        eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (context_ != EGL_NO_CONTEXT) eglDestroyContext(display_, context_);
        if (surface_ != EGL_NO_SURFACE) eglDestroySurface(display_, surface_);
        eglTerminate(display_);
    }
    context_ = EGL_NO_CONTEXT;
    surface_ = EGL_NO_SURFACE;
    display_ = EGL_NO_DISPLAY;

    if (nativeWindow_ != nullptr) {
        OH_NativeWindow_DestroyNativeWindow(nativeWindow_);
        nativeWindow_ = nullptr;
    }
}
