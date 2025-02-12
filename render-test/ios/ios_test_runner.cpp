#include "ios_test_runner.hpp"

#include <mbgl/render_test.hpp>

#include <mbgl/util/logging.hpp>

#include <vector>

#define EXPORT __attribute__((visibility("default")))

EXPORT
bool TestRunner::startTest(const std::string& manifestBasePath) {
    auto runTestWithManifest = [](const std::string& manifest) -> bool {
        std::vector<std::string> arguments = {"mbgl-render-test-runner", "-p", manifest, "-u", "rebaseline"};
        std::vector<char*> argv;
        for (const auto& arg : arguments) {
            argv.push_back(const_cast<char*>(arg.data()));
        }
        argv.push_back(nullptr);

        int finishedTestCount = 0;
        std::function<void()> testStatus = [&]() {
            mbgl::Log::Info(mbgl::Event::General,
                            "Current finished tests number is '" + std::to_string(++finishedTestCount) + "' ");
        };
        mbgl::Log::Info(mbgl::Event::General, "Start running RenderTestRunner with manifest: '" + manifest + "' ");

        auto result = mbgl::runRenderTests(static_cast<int>(argv.size() - 1), argv.data(), testStatus);

        mbgl::Log::Info(mbgl::Event::General,
                        "End running RenderTestRunner with manifest: '" + manifest + "' with result value " +
                            std::to_string(result));
        return result == 0;
    };

    bool status = false;
    try {
#if MH_RENDER_BACKEND_METAL
        status = runTestWithManifest(manifestBasePath + "/ios-metal-render-test-runner-style.json");
        status = runTestWithManifest(manifestBasePath + "/ios-metal-render-test-runner-metrics.json") && status;
#else
        status = runTestWithManifest(manifestBasePath + "/ios-render-test-runner-style.json");
        status = runTestWithManifest(manifestBasePath + "/ios-render-test-runner-metrics.json") && status;
#endif
    } catch (...) {
        mbgl::Log::Info(mbgl::Event::General, "Failed with exception");
    }

    mbgl::Log::Info(mbgl::Event::General, "All tests are finished!");
    if (!status) {
        mbgl::Log::Info(mbgl::Event::General, "There are failing test cases");
    }
    return status;
}
