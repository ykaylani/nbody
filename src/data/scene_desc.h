#ifndef NBODY_SCENE_DESC_H
#define NBODY_SCENE_DESC_H

struct SceneDescription {
    uint32_t bodyCount;
    bool equalMass;

    uint32_t steps;
    float dt;
};

#endif //NBODY_SCENE_DESC_H
