#ifndef NBODY_DISTRIBUTIONS_H
#define NBODY_DISTRIBUTIONS_H
#include <numbers>
#include <random>

constexpr float c_gravitational = 6.6743e-11;

struct Distribution {

    virtual void Apply(float3* positions, float3* velocities, float* masses, float mass_assign, uint32_t count) = 0;
    virtual ~Distribution() = default;
};

namespace Distributions {
    struct RandomCube : Distribution {

        float size_ = 0.0f;
        std::random_device rd;

        void Apply(float3 *positions, float3 *velocities, float *masses, float mass_assign, uint32_t count) override {
            if (size_ == 0) throw std::invalid_argument("Attempt to use RandomCube distribution of size 0");
            std::mt19937 gen(rd());
            std::uniform_real_distribution<float> dist(-size_, size_);

            for (uint32_t i = 0; i < count; i++) {
                positions[i] = {dist(gen), dist(gen), dist(gen)};
                velocities[i] = {0.0f, 0.0f, 0.0f};
                masses[i] = mass_assign;
            }
        }

        RandomCube(float size_) : size_(size_) {}
    };

    struct RandomSphere : Distribution {
        float radius_ = 0.0f;
        std::random_device rd;

        void Apply(float3 *positions, float3 *velocities, float *masses, float mass_assign, uint32_t count) override {
            if (radius_ == 0.0f) throw std::invalid_argument("Attempt to use RandomSphere distribution of radius 0");
            std::mt19937 gen(rd());
            std::uniform_real_distribution<float> dist(-radius_, radius_);

            float radius_sq = radius_ * radius_;

            for (uint32_t i = 0; i < count;) {
                float x = dist(gen);
                float y = dist(gen);
                float z = dist(gen);

                if ((x * x + y * y + z * z) <= radius_sq) {
                    positions[i] = {x, y, z};
                    i++;
                }

                velocities[i] = {0.0f, 0.0f, 0.0f};
                masses[i] = mass_assign;
            }
        }

        RandomSphere(float radius_) : radius_(radius_) {}
    };

    struct Plummer : Distribution {
        std::random_device rd;
        const float lower_bound_ = 0.0001f; // to prevent NaN propagation (along with upper_bound_)
        const float upper_bound_ = 0.99f;

        float max_radius = 15000;
        float scale_radius = 2800;

        float system_mass = 0;

        void Apply(float3* positions, float3* velocities, float* masses, float mass_assign, uint32_t count) override {
            std::mt19937 gen(rd());

            float max_radius_sqr = max_radius * max_radius;
            float scl_radius_sqr = scale_radius * scale_radius;
            float x_max = pow(max_radius_sqr / (max_radius_sqr + scl_radius_sqr), 1.5f);

            std::uniform_real_distribution<float> dist_constrained(lower_bound_, x_max);
            std::uniform_real_distribution<float> dist(0.0f, 1.0f);
            std::uniform_real_distribution<float> dist2(0.0f, 0.1f);

            std::uniform_real_distribution<float> dist_azimuth(0.0f, 2.0f * std::numbers::pi);
            std::uniform_real_distribution<float> dist_cos(-1.0f, 1.0f);

            system_mass = mass_assign * count;

            for (uint32_t i = 0; i < count; i++) {
                float radius = scale_radius / sqrt(pow(dist_constrained(gen), -2.0f/3.0f) - 1);
                float z = radius - 2 * dist(gen) * radius;
                float azimuth = 2 * std::numbers::pi * dist(gen);

                float radius_2D = sqrt(radius * radius - z * z);
                float x = radius_2D * cos(azimuth);
                float y = radius_2D * sin(azimuth);

                positions[i] = {x, y, z};

                // velocities

                float esc_velocity = sqrt(2.0f * c_gravitational * system_mass / sqrt(radius * radius + scale_radius * scale_radius));
                float norm_velocity = 0;
                float criterion = 1;
                float velocity_magnitude = 0;

                while (criterion > norm_velocity * norm_velocity * pow(1 - norm_velocity * norm_velocity, 7.0f/2.0f)) { norm_velocity = dist(gen); criterion = dist2(gen); }
                velocity_magnitude = esc_velocity * norm_velocity;

                float velocity_azimuth = dist_azimuth(gen);
                float cosine = dist_cos(gen);
                float sine = sqrt(1 - cosine * cosine);

                float vx = velocity_magnitude * sine * cos(velocity_azimuth);
                float vy = velocity_magnitude * sine * sin(velocity_azimuth);
                float vz = velocity_magnitude * cosine;

                velocities[i] = {vx, vy, vz};
                masses[i] = mass_assign;
            }
        }

        Plummer(float max_radius_, float scale_radius_) : max_radius(max_radius_), scale_radius(scale_radius_) {}

    };
}


#endif //NBODY_DISTRIBUTIONS_H
