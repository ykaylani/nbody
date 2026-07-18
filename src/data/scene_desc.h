#ifndef NBODY_SCENE_DESC_H
#define NBODY_SCENE_DESC_H

#include "scene_settings.h"
#include "../strats/distributions.h"
#include "../strats/exporters.h"
#include "../strats/solvers.h"

struct SceneDescription {
    SceneSettings settings;

    std::unique_ptr<Solver> solver;
    std::unique_ptr<Distribution> distribution;
    std::unique_ptr<Exporter> exporter;
};

#endif //NBODY_SCENE_DESC_H
