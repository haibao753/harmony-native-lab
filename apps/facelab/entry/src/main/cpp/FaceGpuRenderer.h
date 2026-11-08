#pragma once

#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <native_window/external_window.h>

#include <atomic>
#include <cstdint>
#include <mutex>
#include <thread>
#include <vector>

class FaceGpuRenderer {
public:
    explicit FaceGpuRenderer(uint64_t surfaceId);
    ~FaceGpuRenderer();

    FaceGpuRenderer(const FaceGpuRenderer &) = delete;
    FaceGpuRenderer &operator=(const FaceGpuRenderer &) = delete;

    void Start();
    void Stop();
    void Resize(int32_t width, int32_t height);
    void UpdateMesh(const float *vertices, size_t vertexFloatCount,
                    const uint32_t *triangles, size_t triangleIndexCount,
                    const uint32_t *edges, size_t edgeIndexCount,
                    const float *deformation, size_t deformationCount,
                    float pitch, float yaw, float roll,
                    uint64_t topologyRevision, int32_t mode);
    void ClearMesh();

private:
    struct GpuVertex {
        float position[3];
        float normal[3];
        float heat;
    };

    void RenderLoop();
    bool InitializeEgl();
    bool InitializeGl();
    void RenderFrame();
    void UploadMeshLocked();
    void ReleaseGl();
    void ReleaseEgl();
    GLuint CompileShader(GLenum type, const char *source);
    GLuint CreateProgram();

    uint64_t surfaceId_;
    std::atomic<bool> running_{false};
    std::thread renderThread_;
    std::mutex dataMutex_;

    std::vector<float> vertices_;
    std::vector<uint32_t> triangles_;
    std::vector<uint32_t> edges_;
    std::vector<float> deformation_;
    uint64_t topologyRevision_{UINT64_MAX};
    uint64_t dataRevision_{0};
    uint64_t uploadedRevision_{UINT64_MAX};
    float pitch_{0.0f};
    float yaw_{0.0f};
    float roll_{0.0f};
    int32_t mode_{0};
    int32_t requestedWidth_{0};
    int32_t requestedHeight_{0};
    bool hasMesh_{false};

    OHNativeWindow *nativeWindow_{nullptr};
    EGLDisplay display_{EGL_NO_DISPLAY};
    EGLSurface surface_{EGL_NO_SURFACE};
    EGLContext context_{EGL_NO_CONTEXT};
    EGLConfig config_{nullptr};

    GLuint program_{0};
    GLuint vao_{0};
    GLuint vertexBuffer_{0};
    GLuint triangleBuffer_{0};
    GLuint edgeBuffer_{0};
    GLint poseLocation_{-1};
    GLint aspectLocation_{-1};
    GLint modeLocation_{-1};
    GLsizei triangleIndexCount_{0};
    GLsizei edgeIndexCount_{0};
    int32_t surfaceWidth_{1};
    int32_t surfaceHeight_{1};
};
