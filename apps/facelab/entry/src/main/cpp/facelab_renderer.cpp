#include "facelab_renderer.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <cstddef>
#include <initializer_list>
#include <cstdint>
#include <cstring>
#include <mutex>
#include <thread>
#include <utility>
#include <vector>

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <native_window/external_window.h>

namespace {
constexpr float PI = 3.14159265358979323846f;
constexpr int FRAME_INTERVAL_MS = 33;

struct FaceVertex {
    float px, py, pz;
    float nx, ny, nz;
    float deformation;
    float region;
};

struct RendererStats {
    double renderFps = 0.0;
    double meshUpdateHz = 0.0;
    double napiCopyMs = 0.0;
    double drawCpuMs = 0.0;
    uint32_t vertexCount = 0;
    uint32_t triangleCount = 0;
};

struct MeshSnapshot {
    std::vector<float> positions;
    std::vector<uint32_t> triangles;
    std::vector<uint32_t> edges;
    std::vector<float> deformation;
    std::vector<int32_t> labels;
    float pitch = 0.0f;
    float yaw = 0.0f;
    float roll = 0.0f;
    uint64_t topologyRevision = 0;
    uint64_t revision = 0;
};

void Identity(float m[16])
{
    std::memset(m, 0, sizeof(float) * 16);
    m[0] = 1.0f; m[5] = 1.0f; m[10] = 1.0f; m[15] = 1.0f;
}

void Multiply(float out[16], const float a[16], const float b[16])
{
    float result[16] = {};
    for (int c = 0; c < 4; ++c) {
        for (int r = 0; r < 4; ++r) {
            for (int k = 0; k < 4; ++k) {
                result[c * 4 + r] += a[k * 4 + r] * b[c * 4 + k];
            }
        }
    }
    std::memcpy(out, result, sizeof(result));
}

void RotationX(float angle, float m[16])
{
    Identity(m);
    const float c = std::cos(angle), s = std::sin(angle);
    m[5] = c; m[9] = -s; m[6] = s; m[10] = c;
}

void RotationY(float angle, float m[16])
{
    Identity(m);
    const float c = std::cos(angle), s = std::sin(angle);
    m[0] = c; m[8] = s; m[2] = -s; m[10] = c;
}

void RotationZ(float angle, float m[16])
{
    Identity(m);
    const float c = std::cos(angle), s = std::sin(angle);
    m[0] = c; m[4] = -s; m[1] = s; m[5] = c;
}

void Translation(float z, float m[16])
{
    Identity(m);
    m[14] = z;
}

void Perspective(float fovRadians, float aspect, float nearZ, float farZ, float m[16])
{
    std::memset(m, 0, sizeof(float) * 16);
    const float f = 1.0f / std::tan(fovRadians * 0.5f);
    m[0] = f / std::max(aspect, 0.01f);
    m[5] = f;
    m[10] = (farZ + nearZ) / (nearZ - farZ);
    m[11] = -1.0f;
    m[14] = (2.0f * farZ * nearZ) / (nearZ - farZ);
}

GLuint CompileShader(GLenum type, const char *source)
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

GLuint CreateProgram()
{
    static const char *vertexSource = R"(
        #version 300 es
        precision highp float;
        layout(location = 0) in vec3 aPosition;
        layout(location = 1) in vec3 aNormal;
        layout(location = 2) in float aDeformation;
        layout(location = 3) in float aRegion;
        uniform mat4 uMvp;
        uniform mat4 uModel;
        uniform float uHeatMax;
        out vec3 vNormal;
        out float vHeat;
        out float vRegion;
        void main() {
            gl_Position = uMvp * vec4(aPosition, 1.0);
            vNormal = normalize(mat3(uModel) * aNormal);
            vHeat = clamp(aDeformation / max(uHeatMax, 0.000001), 0.0, 1.0);
            vRegion = aRegion;
        }
    )";
    static const char *fragmentSource = R"(
        #version 300 es
        precision highp float;
        in vec3 vNormal;
        in float vHeat;
        in float vRegion;
        uniform int uMode;
        out vec4 outColor;

        vec3 heatColor(float t) {
            vec3 c0 = vec3(0.08, 0.22, 0.78);
            vec3 c1 = vec3(0.04, 0.72, 0.82);
            vec3 c2 = vec3(0.30, 0.82, 0.43);
            vec3 c3 = vec3(0.98, 0.80, 0.20);
            vec3 c4 = vec3(0.92, 0.18, 0.20);
            if (t < 0.25) return mix(c0, c1, t / 0.25);
            if (t < 0.50) return mix(c1, c2, (t - 0.25) / 0.25);
            if (t < 0.75) return mix(c2, c3, (t - 0.50) / 0.25);
            return mix(c3, c4, (t - 0.75) / 0.25);
        }

        vec3 regionColor(float id) {
            if (id < 0.5) return vec3(0.22, 0.32, 0.45);
            if (id < 1.5) return vec3(0.42, 0.51, 0.63);
            if (id < 2.5) return vec3(0.84, 0.42, 0.63);
            if (id < 3.5) return vec3(0.94, 0.55, 0.71);
            if (id < 4.5) return vec3(0.30, 0.74, 0.82);
            if (id < 5.5) return vec3(0.39, 0.58, 0.90);
            if (id < 6.5) return vec3(0.88, 0.72, 0.36);
            if (id < 7.5) return vec3(0.82, 0.57, 0.30);
            if (id < 8.5) return vec3(0.68, 0.52, 0.84);
            return vec3(0.34, 0.75, 0.58);
        }

        void main() {
            if (uMode == 0) {
                outColor = vec4(0.25, 0.83, 0.91, 1.0);
                return;
            }
            if (uMode == 2) {
                outColor = vec4(heatColor(vHeat), 1.0);
                return;
            }
            if (uMode == 3) {
                outColor = vec4(regionColor(vRegion), 1.0);
                return;
            }
            vec3 n = normalize(vNormal);
            vec3 lightDir = normalize(vec3(-0.35, 0.55, 0.78));
            float diffuse = max(dot(n, lightDir), 0.0);
            float lighting = 0.32 + 0.68 * diffuse;
            vec3 base = vec3(0.23, 0.48, 0.62);
            outColor = vec4(base * lighting, 1.0);
        }
    )";

    GLuint vs = CompileShader(GL_VERTEX_SHADER, vertexSource);
    GLuint fs = CompileShader(GL_FRAGMENT_SHADER, fragmentSource);
    if (vs == 0 || fs == 0) {
        if (vs != 0) glDeleteShader(vs);
        if (fs != 0) glDeleteShader(fs);
        return 0;
    }
    GLuint program = glCreateProgram();
    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);
    glDeleteShader(vs);
    glDeleteShader(fs);
    GLint linked = GL_FALSE;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (linked != GL_TRUE) {
        glDeleteProgram(program);
        return 0;
    }
    return program;
}

class FaceRenderer {
public:
    ~FaceRenderer() { Stop(); }

    bool Start(uint64_t surfaceId)
    {
        Stop();
        OHNativeWindow *window = nullptr;
        if (OH_NativeWindow_CreateNativeWindowFromSurfaceId(surfaceId, &window) != 0 || window == nullptr) {
            return false;
        }
        {
            std::lock_guard<std::mutex> lock(mutex_);
            surfaceId_ = surfaceId;
            window_ = window;
            running_ = true;
        }
        thread_ = std::thread(&FaceRenderer::RenderLoop, this);
        return true;
    }

    void Stop()
    {
        OHNativeWindow *window = nullptr;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (!running_ && window_ == nullptr) return;
            running_ = false;
            window = window_;
        }
        cv_.notify_all();
        if (thread_.joinable()) thread_.join();
        {
            std::lock_guard<std::mutex> lock(mutex_);
            window_ = nullptr;
            surfaceId_ = 0;
            latest_ = MeshSnapshot();
        }
        if (window != nullptr) OH_NativeWindow_DestroyNativeWindow(window);
    }

    void Resize(uint64_t surfaceId, int width, int height)
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (surfaceId != surfaceId_) return;
        width_ = std::max(1, width);
        height_ = std::max(1, height);
        cv_.notify_all();
    }

    void SetMode(int mode)
    {
        std::lock_guard<std::mutex> lock(mutex_);
        mode_ = std::max(0, std::min(3, mode));
    }

    void SetView(float yaw, float pitch, float zoom)
    {
        std::lock_guard<std::mutex> lock(mutex_);
        viewYaw_ = yaw;
        viewPitch_ = pitch;
        zoom_ = std::max(0.65f, std::min(2.8f, zoom));
    }

    void SetNapiCopyMs(double value)
    {
        std::lock_guard<std::mutex> lock(mutex_);
        stats_.napiCopyMs = value;
    }

    RendererStats GetStats()
    {
        std::lock_guard<std::mutex> lock(mutex_);
        return stats_;
    }

    void UpdateMesh(MeshSnapshot snapshot)
    {
        std::lock_guard<std::mutex> lock(mutex_);
        const auto now = std::chrono::steady_clock::now();
        if (lastMeshUpdateTime_.time_since_epoch().count() > 0) {
            const double deltaMs = std::chrono::duration<double, std::milli>(now - lastMeshUpdateTime_).count();
            if (deltaMs > 0.0) {
                const double instantHz = 1000.0 / deltaMs;
                stats_.meshUpdateHz = stats_.meshUpdateHz <= 0.0 ? instantHz :
                    stats_.meshUpdateHz * 0.7 + instantHz * 0.3;
            }
        }
        lastMeshUpdateTime_ = now;
        stats_.vertexCount = static_cast<uint32_t>(snapshot.positions.size() / 3);
        stats_.triangleCount = static_cast<uint32_t>(snapshot.triangles.size() / 3);
        snapshot.revision = latest_.revision + 1;
        latest_ = std::move(snapshot);
        cv_.notify_all();
    }

    void ClearMesh()
    {
        std::lock_guard<std::mutex> lock(mutex_);
        latest_.positions.clear();
        latest_.triangles.clear();
        latest_.edges.clear();
        latest_.deformation.clear();
        latest_.labels.clear();
        latest_.revision++;
        stats_.vertexCount = 0;
        stats_.triangleCount = 0;
        cv_.notify_all();
    }

private:
    bool InitEgl()
    {
        display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        if (display_ == EGL_NO_DISPLAY) return false;
        if (eglInitialize(display_, nullptr, nullptr) != EGL_TRUE) return false;

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
        EGLConfig config = nullptr;
        EGLint configCount = 0;
        if (eglChooseConfig(display_, configAttributes, &config, 1, &configCount) != EGL_TRUE ||
            configCount < 1) return false;

        const EGLint contextAttributes[] = {
            EGL_CONTEXT_CLIENT_VERSION, 3,
            EGL_NONE
        };
        context_ = eglCreateContext(display_, config, EGL_NO_CONTEXT, contextAttributes);
        if (context_ == EGL_NO_CONTEXT) return false;

        EGLNativeWindowType nativeWindow;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            nativeWindow = reinterpret_cast<EGLNativeWindowType>(window_);
        }
        surface_ = eglCreateWindowSurface(display_, config, nativeWindow, nullptr);
        if (surface_ == EGL_NO_SURFACE) return false;
        if (eglMakeCurrent(display_, surface_, surface_, context_) != EGL_TRUE) return false;
        eglSwapInterval(display_, 1);
        return true;
    }

    void ReleaseEgl()
    {
        if (display_ != EGL_NO_DISPLAY) {
            eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
            if (surface_ != EGL_NO_SURFACE) eglDestroySurface(display_, surface_);
            if (context_ != EGL_NO_CONTEXT) eglDestroyContext(display_, context_);
            eglTerminate(display_);
        }
        display_ = EGL_NO_DISPLAY;
        surface_ = EGL_NO_SURFACE;
        context_ = EGL_NO_CONTEXT;
    }

    bool InitGl()
    {
        program_ = CreateProgram();
        if (program_ == 0) return false;
        uMvp_ = glGetUniformLocation(program_, "uMvp");
        uModel_ = glGetUniformLocation(program_, "uModel");
        uMode_ = glGetUniformLocation(program_, "uMode");
        uHeatMax_ = glGetUniformLocation(program_, "uHeatMax");
        glGenVertexArrays(1, &vao_);
        glGenBuffers(1, &vbo_);
        glGenBuffers(1, &triangleEbo_);
        glGenBuffers(1, &edgeEbo_);
        glBindVertexArray(vao_);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(FaceVertex),
            reinterpret_cast<void *>(offsetof(FaceVertex, px)));
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(FaceVertex),
            reinterpret_cast<void *>(offsetof(FaceVertex, nx)));
        glEnableVertexAttribArray(2);
        glVertexAttribPointer(2, 1, GL_FLOAT, GL_FALSE, sizeof(FaceVertex),
            reinterpret_cast<void *>(offsetof(FaceVertex, deformation)));
        glEnableVertexAttribArray(3);
        glVertexAttribPointer(3, 1, GL_FLOAT, GL_FALSE, sizeof(FaceVertex),
            reinterpret_cast<void *>(offsetof(FaceVertex, region)));
        glBindVertexArray(0);
        glEnable(GL_DEPTH_TEST);
        glDisable(GL_CULL_FACE);
        return glGetError() == GL_NO_ERROR;
    }

    void UploadMesh(const MeshSnapshot &mesh)
    {
        const size_t vertexCount = mesh.positions.size() / 3;
        const size_t triangleCount = mesh.triangles.size();
        if (vertexCount == 0 || triangleCount < 3) {
            vertexCount_ = 0;
            triangleIndexCount_ = 0;
            edgeIndexCount_ = 0;
            uploadedTopologyRevision_ = UINT64_MAX;
            return;
        }

        float minX = mesh.positions[0], maxX = mesh.positions[0];
        float minY = mesh.positions[1], maxY = mesh.positions[1];
        float minZ = mesh.positions[2], maxZ = mesh.positions[2];
        for (size_t i = 0; i < vertexCount; ++i) {
            const float x = mesh.positions[i * 3];
            const float y = mesh.positions[i * 3 + 1];
            const float z = mesh.positions[i * 3 + 2];
            minX = std::min(minX, x); maxX = std::max(maxX, x);
            minY = std::min(minY, y); maxY = std::max(maxY, y);
            minZ = std::min(minZ, z); maxZ = std::max(maxZ, z);
        }
        const float cx = (minX + maxX) * 0.5f;
        const float cy = (minY + maxY) * 0.5f;
        const float cz = (minZ + maxZ) * 0.5f;
        const float extent = std::max({maxX - minX, maxY - minY, maxZ - minZ, 0.0001f});
        const float scale = 1.65f / extent;

        std::vector<FaceVertex> vertices(vertexCount);
        std::vector<float> normalSums(vertexCount * 3, 0.0f);
        std::vector<float> regionSums(vertexCount, 0.0f);
        std::vector<uint32_t> regionCounts(vertexCount, 0);
        float maxHeat = 0.0f;

        for (size_t i = 0; i < vertexCount; ++i) {
            FaceVertex &v = vertices[i];
            v.px = (mesh.positions[i * 3] - cx) * scale;
            v.py = (mesh.positions[i * 3 + 1] - cy) * scale;
            v.pz = (mesh.positions[i * 3 + 2] - cz) * scale;
            v.nx = v.ny = v.nz = 0.0f;
            v.deformation = i < mesh.deformation.size() ? std::max(0.0f, mesh.deformation[i]) : 0.0f;
            v.region = 0.0f;
            maxHeat = std::max(maxHeat, v.deformation);
        }

        for (size_t i = 0; i + 2 < triangleCount; i += 3) {
            const uint32_t a = mesh.triangles[i];
            const uint32_t b = mesh.triangles[i + 1];
            const uint32_t c = mesh.triangles[i + 2];
            if (a >= vertexCount || b >= vertexCount || c >= vertexCount) continue;
            const FaceVertex &va = vertices[a];
            const FaceVertex &vb = vertices[b];
            const FaceVertex &vc = vertices[c];
            const float abx = vb.px - va.px, aby = vb.py - va.py, abz = vb.pz - va.pz;
            const float acx = vc.px - va.px, acy = vc.py - va.py, acz = vc.pz - va.pz;
            const float nx = aby * acz - abz * acy;
            const float ny = abz * acx - abx * acz;
            const float nz = abx * acy - aby * acx;
            for (uint32_t index : {a, b, c}) {
                normalSums[index * 3] += nx;
                normalSums[index * 3 + 1] += ny;
                normalSums[index * 3 + 2] += nz;
            }
            const size_t triangleNumber = i / 3;
            if (triangleNumber < mesh.labels.size()) {
                const float region = static_cast<float>(std::max(0, std::min(9, mesh.labels[triangleNumber] + 1)));
                for (uint32_t index : {a, b, c}) {
                    regionSums[index] += region;
                    regionCounts[index]++;
                }
            }
        }

        for (size_t i = 0; i < vertexCount; ++i) {
            float nx = normalSums[i * 3], ny = normalSums[i * 3 + 1], nz = normalSums[i * 3 + 2];
            const float length = std::sqrt(nx * nx + ny * ny + nz * nz);
            if (length > 0.000001f) {
                nx /= length; ny /= length; nz /= length;
            } else {
                nx = 0.0f; ny = 0.0f; nz = 1.0f;
            }
            vertices[i].nx = nx; vertices[i].ny = ny; vertices[i].nz = nz;
            if (regionCounts[i] > 0) {
                vertices[i].region = std::round(regionSums[i] / static_cast<float>(regionCounts[i]));
            }
        }

        glBindVertexArray(vao_);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_);
        const GLsizeiptr vertexBytes = static_cast<GLsizeiptr>(vertices.size() * sizeof(FaceVertex));
        if (vertexBytes > vertexCapacity_) {
            glBufferData(GL_ARRAY_BUFFER, vertexBytes, vertices.data(), GL_DYNAMIC_DRAW);
            vertexCapacity_ = vertexBytes;
        } else {
            glBufferSubData(GL_ARRAY_BUFFER, 0, vertexBytes, vertices.data());
        }

        const GLsizeiptr triangleBytes = static_cast<GLsizeiptr>(mesh.triangles.size() * sizeof(uint32_t));
        const GLsizeiptr edgeBytes = static_cast<GLsizeiptr>(mesh.edges.size() * sizeof(uint32_t));
        const bool topologyChanged = mesh.topologyRevision != uploadedTopologyRevision_ ||
            triangleBytes > triangleCapacity_ || edgeBytes > edgeCapacity_;
        if (topologyChanged) {
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, triangleEbo_);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, triangleBytes, mesh.triangles.data(), GL_DYNAMIC_DRAW);
            triangleCapacity_ = triangleBytes;
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, edgeEbo_);
            if (edgeBytes > 0) {
                glBufferData(GL_ELEMENT_ARRAY_BUFFER, edgeBytes, mesh.edges.data(), GL_DYNAMIC_DRAW);
            }
            edgeCapacity_ = edgeBytes;
            uploadedTopologyRevision_ = mesh.topologyRevision;
        }
        glBindVertexArray(0);

        vertexCount_ = static_cast<GLsizei>(vertexCount);
        triangleIndexCount_ = static_cast<GLsizei>(mesh.triangles.size());
        edgeIndexCount_ = static_cast<GLsizei>(mesh.edges.size());
        heatMax_ = std::max(maxHeat, 0.000001f);
    }

    void Draw(const MeshSnapshot &mesh, int mode, int width, int height,
        float viewYaw, float viewPitch, float zoom)
    {
        glViewport(0, 0, width, height);
        glClearColor(0.035f, 0.065f, 0.105f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        if (program_ == 0 || vertexCount_ == 0) return;

        float rx[16], ry[16], rz[16], scaleMatrix[16], modelA[16], model[16], view[16], projection[16], mvp[16];
        RotationX(mesh.pitch * PI / 180.0f + viewPitch, rx);
        RotationY(mesh.yaw * PI / 180.0f + viewYaw, ry);
        RotationZ(mesh.roll * PI / 180.0f, rz);
        Multiply(modelA, ry, rx);
        Multiply(model, rz, modelA);
        Identity(scaleMatrix);
        scaleMatrix[0] = zoom; scaleMatrix[5] = zoom; scaleMatrix[10] = zoom;
        Multiply(modelA, model, scaleMatrix);
        std::memcpy(model, modelA, sizeof(model));
        Translation(-3.2f, view);
        Perspective(PI / 4.0f, static_cast<float>(width) / static_cast<float>(std::max(1, height)),
            0.1f, 20.0f, projection);
        Multiply(modelA, view, model);
        Multiply(mvp, projection, modelA);

        glUseProgram(program_);
        glUniformMatrix4fv(uMvp_, 1, GL_FALSE, mvp);
        glUniformMatrix4fv(uModel_, 1, GL_FALSE, model);
        glUniform1i(uMode_, mode);
        glUniform1f(uHeatMax_, heatMax_);
        glBindVertexArray(vao_);
        if (mode == 0) {
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, edgeEbo_);
            glLineWidth(1.0f);
            glDrawElements(GL_LINES, edgeIndexCount_, GL_UNSIGNED_INT, nullptr);
        } else {
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, triangleEbo_);
            glDrawElements(GL_TRIANGLES, triangleIndexCount_, GL_UNSIGNED_INT, nullptr);
        }
        glBindVertexArray(0);
        glUseProgram(0);
    }

    void RenderLoop()
    {
        if (!InitEgl() || !InitGl()) {
            ReleaseEgl();
            return;
        }
        uint64_t uploadedRevision = 0;
        MeshSnapshot current;
        auto nextFrame = std::chrono::steady_clock::now();
        while (true) {
            int width, height, mode;
            float viewYaw, viewPitch, zoom;
            MeshSnapshot pending;
            bool hasNewMesh = false;
            {
                std::unique_lock<std::mutex> lock(mutex_);
                cv_.wait_for(lock, std::chrono::milliseconds(FRAME_INTERVAL_MS), [this, uploadedRevision]() {
                    return !running_ || latest_.revision != uploadedRevision;
                });
                if (!running_) break;
                if (latest_.revision != uploadedRevision) {
                    pending = latest_;
                    uploadedRevision = latest_.revision;
                    hasNewMesh = true;
                }
                width = width_;
                height = height_;
                mode = mode_;
                viewYaw = viewYaw_;
                viewPitch = viewPitch_;
                zoom = zoom_;
            }
            if (hasNewMesh) {
                current = std::move(pending);
                UploadMesh(current);
            }
            const auto drawStarted = std::chrono::steady_clock::now();
            Draw(current, mode, width, height, viewYaw, viewPitch, zoom);
            const double drawMs = std::chrono::duration<double, std::milli>(
                std::chrono::steady_clock::now() - drawStarted).count();
            eglSwapBuffers(display_, surface_);
            {
                std::lock_guard<std::mutex> lock(mutex_);
                stats_.drawCpuMs = drawMs;
                framesInStatsWindow_++;
                const auto now = std::chrono::steady_clock::now();
                if (statsWindowStart_.time_since_epoch().count() == 0) {
                    statsWindowStart_ = now;
                } else {
                    const double windowSeconds = std::chrono::duration<double>(now - statsWindowStart_).count();
                    if (windowSeconds >= 1.0) {
                        stats_.renderFps = static_cast<double>(framesInStatsWindow_) / windowSeconds;
                        framesInStatsWindow_ = 0;
                        statsWindowStart_ = now;
                    }
                }
            }
            nextFrame += std::chrono::milliseconds(FRAME_INTERVAL_MS);
            std::this_thread::sleep_until(nextFrame);
            if (std::chrono::steady_clock::now() - nextFrame > std::chrono::milliseconds(100)) {
                nextFrame = std::chrono::steady_clock::now();
            }
        }
        if (vao_ != 0) glDeleteVertexArrays(1, &vao_);
        if (vbo_ != 0) glDeleteBuffers(1, &vbo_);
        if (triangleEbo_ != 0) glDeleteBuffers(1, &triangleEbo_);
        if (edgeEbo_ != 0) glDeleteBuffers(1, &edgeEbo_);
        if (program_ != 0) glDeleteProgram(program_);
        vao_ = vbo_ = triangleEbo_ = edgeEbo_ = program_ = 0;
        ReleaseEgl();
    }

    std::mutex mutex_;
    std::condition_variable cv_;
    std::thread thread_;
    bool running_ = false;
    uint64_t surfaceId_ = 0;
    OHNativeWindow *window_ = nullptr;
    int width_ = 800;
    int height_ = 600;
    int mode_ = 1;
    float viewYaw_ = 0.0f;
    float viewPitch_ = 0.0f;
    float zoom_ = 1.0f;
    MeshSnapshot latest_;
    RendererStats stats_;
    std::chrono::steady_clock::time_point lastMeshUpdateTime_{};
    std::chrono::steady_clock::time_point statsWindowStart_{};
    uint32_t framesInStatsWindow_ = 0;

    EGLDisplay display_ = EGL_NO_DISPLAY;
    EGLSurface surface_ = EGL_NO_SURFACE;
    EGLContext context_ = EGL_NO_CONTEXT;
    GLuint program_ = 0;
    GLuint vao_ = 0;
    GLuint vbo_ = 0;
    GLuint triangleEbo_ = 0;
    GLuint edgeEbo_ = 0;
    GLint uMvp_ = -1;
    GLint uModel_ = -1;
    GLint uMode_ = -1;
    GLint uHeatMax_ = -1;
    GLsizeiptr vertexCapacity_ = 0;
    GLsizeiptr triangleCapacity_ = 0;
    GLsizeiptr edgeCapacity_ = 0;
    uint64_t uploadedTopologyRevision_ = UINT64_MAX;
    GLsizei vertexCount_ = 0;
    GLsizei triangleIndexCount_ = 0;
    GLsizei edgeIndexCount_ = 0;
    float heatMax_ = 1.0f;
};

FaceRenderer gRenderer;

bool ReadTypedArray(napi_env env, napi_value value, napi_typedarray_type expected, void **data, size_t *length)
{
    napi_typedarray_type actual;
    napi_value arrayBuffer = nullptr;
    size_t byteOffset = 0;
    if (napi_get_typedarray_info(env, value, &actual, length, data, &arrayBuffer, &byteOffset) != napi_ok) {
        return false;
    }
    if (actual != expected || (*length % sizeof(uint32_t)) != 0) {
        return false;
    }
    // HarmonyOS Node-API reports TypedArray length in bytes rather than elements.
    *length /= sizeof(uint32_t);
    return true;
}

bool ReadBigInt(napi_env env, napi_value value, uint64_t *result)
{
    int64_t signedValue = 0;
    bool lossless = false;
    if (napi_get_value_bigint_int64(env, value, &signedValue, &lossless) != napi_ok ||
        !lossless || signedValue < 0) {
        return false;
    }
    *result = static_cast<uint64_t>(signedValue);
    return true;
}

napi_value ReturnUndefined(napi_env env)
{
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value SetSurfaceId(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    uint64_t surfaceId = 0;
    if (argc < 1 || !ReadBigInt(env, args[0], &surfaceId)) return ReturnUndefined(env);
    gRenderer.Start(surfaceId);
    return ReturnUndefined(env);
}

napi_value ChangeSurface(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    uint64_t surfaceId = 0;
    int32_t width = 1, height = 1;
    if (argc < 3 || !ReadBigInt(env, args[0], &surfaceId)) return ReturnUndefined(env);
    napi_get_value_int32(env, args[1], &width);
    napi_get_value_int32(env, args[2], &height);
    gRenderer.Resize(surfaceId, width, height);
    return ReturnUndefined(env);
}

napi_value DestroySurface(napi_env env, napi_callback_info info)
{
    gRenderer.Stop();
    return ReturnUndefined(env);
}

napi_value SetMode(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    int32_t mode = 1;
    if (argc > 0) napi_get_value_int32(env, args[0], &mode);
    gRenderer.SetMode(mode);
    return ReturnUndefined(env);
}

napi_value SetViewTransform(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    double yaw = 0.0, pitch = 0.0, zoom = 1.0;
    if (argc >= 3) {
        napi_get_value_double(env, args[0], &yaw);
        napi_get_value_double(env, args[1], &pitch);
        napi_get_value_double(env, args[2], &zoom);
    }
    gRenderer.SetView(static_cast<float>(yaw), static_cast<float>(pitch), static_cast<float>(zoom));
    return ReturnUndefined(env);
}

napi_value UpdateMesh(napi_env env, napi_callback_info info)
{
    size_t argc = 9;
    napi_value args[9] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (argc < 9) return ReturnUndefined(env);

    void *verticesData = nullptr, *trianglesData = nullptr, *edgesData = nullptr;
    void *deformationData = nullptr, *labelsData = nullptr;
    size_t verticesLength = 0, trianglesLength = 0, edgesLength = 0;
    size_t deformationLength = 0, labelsLength = 0;
    if (!ReadTypedArray(env, args[0], napi_float32_array, &verticesData, &verticesLength) ||
        !ReadTypedArray(env, args[1], napi_uint32_array, &trianglesData, &trianglesLength) ||
        !ReadTypedArray(env, args[2], napi_uint32_array, &edgesData, &edgesLength) ||
        !ReadTypedArray(env, args[3], napi_float32_array, &deformationData, &deformationLength) ||
        !ReadTypedArray(env, args[4], napi_int32_array, &labelsData, &labelsLength)) {
        return ReturnUndefined(env);
    }

    const auto copyStarted = std::chrono::steady_clock::now();
    MeshSnapshot snapshot;
    const float *vertices = static_cast<const float *>(verticesData);
    const uint32_t *triangles = static_cast<const uint32_t *>(trianglesData);
    const uint32_t *edges = static_cast<const uint32_t *>(edgesData);
    const float *deformation = static_cast<const float *>(deformationData);
    const int32_t *labels = static_cast<const int32_t *>(labelsData);
    if (verticesLength > 0) snapshot.positions.assign(vertices, vertices + verticesLength);
    if (trianglesLength > 0) snapshot.triangles.assign(triangles, triangles + trianglesLength);
    if (edgesLength > 0) snapshot.edges.assign(edges, edges + edgesLength);
    if (deformationLength > 0) snapshot.deformation.assign(deformation, deformation + deformationLength);
    if (labelsLength > 0) snapshot.labels.assign(labels, labels + labelsLength);
    double pitch = 0.0, yaw = 0.0, roll = 0.0;
    int64_t topologyRevision = 0;
    napi_get_value_double(env, args[5], &pitch);
    napi_get_value_double(env, args[6], &yaw);
    napi_get_value_double(env, args[7], &roll);
    napi_get_value_int64(env, args[8], &topologyRevision);
    snapshot.topologyRevision = static_cast<uint64_t>(std::max<int64_t>(0, topologyRevision));
    snapshot.pitch = static_cast<float>(pitch);
    snapshot.yaw = static_cast<float>(yaw);
    snapshot.roll = static_cast<float>(roll);
    const double copyMs = std::chrono::duration<double, std::milli>(
        std::chrono::steady_clock::now() - copyStarted).count();
    gRenderer.SetNapiCopyMs(copyMs);
    gRenderer.UpdateMesh(std::move(snapshot));
    return ReturnUndefined(env);
}

napi_value GetStats(napi_env env, napi_callback_info info)
{
    const RendererStats stats = gRenderer.GetStats();
    napi_value result = nullptr;
    napi_create_object(env, &result);
    napi_value value = nullptr;
    napi_create_double(env, stats.renderFps, &value);
    napi_set_named_property(env, result, "renderFps", value);
    napi_create_double(env, stats.meshUpdateHz, &value);
    napi_set_named_property(env, result, "meshUpdateHz", value);
    napi_create_double(env, stats.napiCopyMs, &value);
    napi_set_named_property(env, result, "napiCopyMs", value);
    napi_create_double(env, stats.drawCpuMs, &value);
    napi_set_named_property(env, result, "drawCpuMs", value);
    napi_create_uint32(env, stats.vertexCount, &value);
    napi_set_named_property(env, result, "vertexCount", value);
    napi_create_uint32(env, stats.triangleCount, &value);
    napi_set_named_property(env, result, "triangleCount", value);
    return result;
}

napi_value ClearMesh(napi_env env, napi_callback_info info)
{
    gRenderer.ClearMesh();
    return ReturnUndefined(env);
}
} // namespace

napi_value RegisterRenderer(napi_env env, napi_value exports)
{
    napi_property_descriptor properties[] = {
        {"SetSurfaceId", nullptr, SetSurfaceId, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"ChangeSurface", nullptr, ChangeSurface, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"DestroySurface", nullptr, DestroySurface, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"UpdateMesh", nullptr, UpdateMesh, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"ClearMesh", nullptr, ClearMesh, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"SetMode", nullptr, SetMode, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"SetViewTransform", nullptr, SetViewTransform, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"GetStats", nullptr, GetStats, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    napi_define_properties(env, exports, sizeof(properties) / sizeof(properties[0]), properties);
    return exports;
}
