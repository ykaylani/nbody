#ifndef NBODY_SCENE_DESC_H
#define NBODY_SCENE_DESC_H

#include <optional>

#include "../distributions.h"
#include "../exporters.h"

struct SceneDescription {
    std::unique_ptr<Distribution> distribution_;
    std::unique_ptr<Exporter> exporter_;

    uint32_t body_count_;
    uint32_t steps_;
    float dt_;
    float softening_;

    bool equal_mass_;
    bool cuda_err_;
};

#endif //NBODY_SCENE_DESC_H
