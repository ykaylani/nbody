#ifndef NBODY_DISTRIBUTIONS_H
#define NBODY_DISTRIBUTIONS_H
#include "data/scene_desc.h"

namespace RandomCube {
    inline float3 InitialPosition(int size_positive, int size_negative) {
        return {(float)(rand() % size_positive - size_negative), (float)(rand() % size_positive - size_negative), (float)(rand() % size_positive - size_negative)};
    }
}

template<typename... Args>
float3 GetPosition(SceneDistribution distribution, Args&&... args) {
    switch (distribution) {
        case SceneDistribution::RANDOM_CUBE:
            return RandomCube::InitialPosition(args...);
            break;
        default:
            throw std::invalid_argument("Unknown distribution");
    }
}

#endif //NBODY_DISTRIBUTIONS_H
