#ifndef NBODY_SCENE_DESC_H
#define NBODY_SCENE_DESC_H

#include <filesystem>
#include <optional>

struct SceneDescription {
    uint32_t body_count_;
    uint32_t steps_;
    float dt_;

    bool equal_mass_;
    bool cuda_err_;

    bool export_data_;
    std::optional<std::filesystem::path> data_directory_;
};

#endif //NBODY_SCENE_DESC_H
