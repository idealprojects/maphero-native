#include <mbgl/gl/context.hpp>
#include <mbgl/gl/vertex_buffer_resource.hpp>
#include <mbgl/util/instrumentation.hpp>

namespace mbgl {
namespace gl {

VertexBufferResource::VertexBufferResource(UniqueBuffer&& buffer_, int byteSize_)
    : buffer(std::move(buffer_)),
      byteSize(byteSize_) {
    MH_TRACE_ALLOC_VERTEX_BUFFER(buffer.get(), byteSize);

    if (buffer) {
        auto& stats = buffer.get_deleter().context.renderingStats();
        stats.numVertexBuffers++;
        stats.memVertexBuffers += byteSize;

        stats.numBuffers++;
        stats.totalBuffers++;
        stats.memBuffers += byteSize;
    }
}

VertexBufferResource::~VertexBufferResource() noexcept {
    MH_TRACE_FREE_VERTEX_BUFFER(buffer.get());

    if (buffer) {
        auto& stats = buffer.get_deleter().context.renderingStats();
        stats.numVertexBuffers--;
        stats.memVertexBuffers -= byteSize;
        stats.memBuffers -= byteSize;

        assert(stats.memVertexBuffers >= 0);
    }
}

} // namespace gl
} // namespace mbgl
