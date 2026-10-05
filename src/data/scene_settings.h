#ifndef NBODY_SCENE_SETTINGS_H
#define NBODY_SCENE_SETTINGS_H

struct SceneSettings {
    uint32_t body_count;
    uint32_t steps;
    float dt;
    float softening;

    bool cuda_err;
    bool hotloop_time;
    bool total_hotloop_time;

    bool visualize;
    bool visualize_tree;

    float min_node_extent;
    uint32_t n_frames_snap;
};

#endif //NBODY_SCENE_SETTINGS_H
