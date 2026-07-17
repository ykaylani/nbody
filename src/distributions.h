#ifndef NBODY_DISTRIBUTIONS_H
#define NBODY_DISTRIBUTIONS_H
#include <random>

struct Distribution {
    virtual void ApplyPositions(float3* positions, uint32_t count) = 0;
    virtual void ApplyVelocities(float3* velocities, uint32_t count) = 0;

    virtual ~Distribution() = default;
};

struct RandomCube : Distribution {

    float size_ = 0.0f;
    std::random_device rd;

    void ApplyPositions(float3* positions, uint32_t count) override {
        if (size_ == 0) throw std::invalid_argument("Attempt to use RandomCube distribution of size 0");
        std::mt19937 gen(rd());
        std::uniform_real_distribution<float> dist(-size_, size_);

        for (int i = 0; i < count; i++) {
            positions[i] = {dist(gen), dist(gen), dist(gen)};
        }
    }

    void ApplyVelocities(float3* velocities, uint32_t count) override {
        for (uint32_t i = 0; i < count; i++) {
            velocities[i] = {0.0f, 0.0f, 0.0f};
        }
    };

    RandomCube(float size_) : size_(size_) {}
};


#endif //NBODY_DISTRIBUTIONS_H
