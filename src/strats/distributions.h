#ifndef NBODY_DISTRIBUTIONS_H
#define NBODY_DISTRIBUTIONS_H
#include <numbers>
#include <random>
#include <cmath>
#include <algorithm>
#include <stdexcept>

constexpr float c_gravitational = 6.6743e-11;

struct Distribution {
    SceneSettings scene_settings;

    virtual void Apply(float4* positions, float4* velocities, float mass_assign) = 0;
    virtual ~Distribution() = default;

    Distribution(SceneSettings scene_settings) : scene_settings(scene_settings) {}
};

namespace Distributions {
    struct RandomCube : Distribution {

        float size_ = 0.0f;
        std::random_device rd;

        void Apply(float4 *positions, float4 *velocities, float mass_assign) override {
            if (size_ == 0) throw std::invalid_argument("Attempt to use RandomCube distribution of size 0");
            std::mt19937 gen(rd());
            std::uniform_real_distribution<float> dist(-size_, size_);

            for (uint32_t i = 0; i < scene_settings.body_count; i++) {
                positions[i] = {dist(gen), dist(gen), dist(gen), mass_assign};
                velocities[i] = {0.0f, 0.0f, 0.0f, 0.0f};
            }
        }

        RandomCube(const SceneSettings &scene_settings, float size) : Distribution(scene_settings), size_(size) {}
    };

    struct RandomSphere : Distribution {
        float radius_ = 0.0f;
        std::random_device rd;

        void Apply(float4 *positions, float4 *velocities, float mass_assign) override {
            if (radius_ == 0.0f) throw std::invalid_argument("Attempt to use RandomSphere distribution of radius 0");
            std::mt19937 gen(rd());
            std::uniform_real_distribution<float> dist(-radius_, radius_);

            float radius_sq = radius_ * radius_;

            for (uint32_t i = 0; i < scene_settings.body_count;) {
                float x = dist(gen);
                float y = dist(gen);
                float z = dist(gen);

                if ((x * x + y * y + z * z) <= radius_sq) {
                    positions[i] = {x, y, z, mass_assign};
                    velocities[i] = {0.0f, 0.0f, 0.0f, 0.0f};
                    i++;
                }
            }
        }

        RandomSphere(const SceneSettings &scene_settings, float radius) : Distribution(scene_settings), radius_(radius) {}
    };

    struct Plummer : Distribution {
        std::random_device rd;
        const float lower_bound_ = 0.0001f;

        float max_radius = 15000;
        float scale_radius = 2800;

        float system_mass = 0;

        void Apply(float4* positions, float4* velocities, float mass_assign) override {
            if (scale_radius == 0.0f) throw std::invalid_argument("Attempt to use Plummer distribution of scale radius 0");
            if (max_radius == 0.0f) throw std::invalid_argument("Attempt to use Plummer distribution of max radius 0");

            std::mt19937 gen(rd());

            float max_radius_sqr = max_radius * max_radius;
            float scl_radius_sqr = scale_radius * scale_radius;
            float x_max = pow(max_radius_sqr / (max_radius_sqr + scl_radius_sqr), 1.5f);

            std::uniform_real_distribution<float> dist_constrained(lower_bound_, x_max);
            std::uniform_real_distribution<float> dist(0.0f, 1.0f);
            std::uniform_real_distribution<float> dist2(0.0f, 0.1f);

            std::uniform_real_distribution<float> dist_azimuth(0.0f, 2.0f * std::numbers::pi);
            std::uniform_real_distribution<float> dist_cos(-1.0f, 1.0f);

            system_mass = mass_assign * scene_settings.body_count;

            for (uint32_t i = 0; i < scene_settings.body_count; i++) {
                float radius = scale_radius / sqrt(pow(dist_constrained(gen), -2.0f/3.0f) - 1);
                float z = radius - 2 * dist(gen) * radius;
                float azimuth = 2 * std::numbers::pi * dist(gen);

                float radius_2D = sqrt(std::max(0.0f, radius * radius - z * z));
                float x = radius_2D * cos(azimuth);
                float y = radius_2D * sin(azimuth);

                positions[i] = {x, y, z, mass_assign};

                // velocities

                float esc_velocity = sqrt(2.0f * c_gravitational * system_mass / sqrt(radius * radius + scale_radius * scale_radius));
                float norm_velocity = 0;
                float criterion = 1;
                float velocity_magnitude = 0;

                while (criterion > norm_velocity * norm_velocity * std::pow(1 - norm_velocity * norm_velocity, 7.0f/2.0f)) { norm_velocity = dist(gen); criterion = dist2(gen); }
                velocity_magnitude = esc_velocity * norm_velocity;

                float velocity_azimuth = dist_azimuth(gen);
                float cosine = dist_cos(gen);
                float sine = sqrt(1 - cosine * cosine);

                float vx = velocity_magnitude * sine * cos(velocity_azimuth);
                float vy = velocity_magnitude * sine * sin(velocity_azimuth);
                float vz = velocity_magnitude * cosine;

                velocities[i] = {vx, vy, vz, 0.0f};
            }
        }

        Plummer(const SceneSettings &scene_settings, float max_radius_, float scale_radius_) :Distribution(scene_settings), max_radius(max_radius_), scale_radius(scale_radius_) {}
    };

    struct Kuzmin : Distribution {
        std::random_device rd;

        float max_radius = 15000;
        float scale_radius = 2800;
        float scale_height = 0.0f;

        float system_mass = 0;

        void Apply(float4* positions, float4* velocities, float mass_assign) override {
            if (scale_radius == 0.0f) throw std::invalid_argument("Attempt to use Kuzmin distribution of scale radius 0");
            if (max_radius == 0.0f) throw std::invalid_argument("Attempt to use Kuzmin distribution of max radius 0");

            std::mt19937 gen(rd());
            float a = scale_radius;
            float a_sqr = a * a;

            float u_max = 1.0f - a / sqrt(max_radius * max_radius + a_sqr);

            std::uniform_real_distribution<float> dist_u(0.0f, u_max);
            std::uniform_real_distribution<float> dist_azimuth(0.0f, 2.0f * std::numbers::pi);

            std::exponential_distribution<float> dist_height(scale_height > 0.0f ? 1.0f / scale_height : 1.0f);
            std::bernoulli_distribution dist_sign(0.5);

            system_mass = mass_assign * scene_settings.body_count;

            for (uint32_t i = 0; i < scene_settings.body_count; i++) {
                float u = dist_u(gen);
                float radius = a * sqrt(u * (2.0f - u)) / (1.0f - u);
                float azimuth = dist_azimuth(gen);

                float x = radius * cos(azimuth);
                float z = radius * sin(azimuth);

                float height = 0.0f;
                if (scale_height > 0.0f) {
                    height = dist_height(gen);
                    if (dist_sign(gen)) height = -height;
                }

                positions[i] = {x, height, z, mass_assign};

                float a_eff = a + std::fabs(height);
                float denom = pow(radius * radius + a_eff * a_eff, 1.5f);
                float v_c = sqrt(c_gravitational * system_mass * radius * radius / denom);

                velocities[i] = {-v_c * sin(azimuth), 0.0f, v_c * cos(azimuth), 0.0f};
            }
        }

        Kuzmin(const SceneSettings &scene_settings, float max_radius_, float scale_radius_, float scale_height_ = 0.0f) : Distribution(scene_settings), max_radius(max_radius_), scale_radius(scale_radius_), scale_height(scale_height_) {}
    };
}


#endif //NBODY_DISTRIBUTIONS_H