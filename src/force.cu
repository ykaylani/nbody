__constant__ float c_gravitational = 6.6743e-11;

__global__ void Run(float3* positions, float3* velocities, float3* positions2, float3* velocities2, float* inv_masses, uint32_t bodyCount, float dt, uint32_t step, bool equalMass) {
    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= bodyCount) return;

    float3 force = {0, 0, 0};

    float3 process_pos;
    float3 process_velocity;
    float process_invmass;

    if (equalMass) { process_invmass = *inv_masses; } else { process_invmass = inv_masses[idx]; }

    if (step % 2 == 0) {
        process_pos = positions[idx];
        process_velocity = velocities[idx];
    } else {
        process_pos = positions2[idx];
        process_velocity = velocities2[idx];
    }

    for (int i = 0; i < bodyCount; i++) {
        if (i == idx) { continue; }

        float3 selected_pos;

        if (step % 2 == 0) {
            selected_pos = positions[i];
        } else {
            selected_pos = positions2[i];
        }

        float sel_invmass;
        if (equalMass) { sel_invmass = *inv_masses; } else { sel_invmass = process_invmass; }

        float3 disp = {selected_pos.x - process_pos.x, selected_pos.y - process_pos.y, selected_pos.z - process_pos.z};

        float dist_sqr = disp.x * disp.x + disp.y * disp.y + disp.z * disp.z;
        float disp_magnitude_inv = rsqrt(dist_sqr);

        if (dist_sqr < 0.01f) { continue; }
        float force_magnitude = c_gravitational / (sel_invmass * process_invmass * (dist_sqr + 5)); //constant is softening

        float3 disp_unit = {disp.x * disp_magnitude_inv, disp.y * disp_magnitude_inv, disp.z * disp_magnitude_inv};
        float3 total = {disp_unit.x * force_magnitude, disp_unit.y * force_magnitude, disp_unit.z * force_magnitude};

        force = {force.x + total.x, force.y + total.y, force.z + total.z};
    }

    float3 scaledForce = {force.x * dt * process_invmass, force.y * dt * process_invmass, force.z * dt * process_invmass};
    float3 vel_new = {process_velocity.x + scaledForce.x, process_velocity.y + scaledForce.y, process_velocity.z + scaledForce.z};

    if (step % 2 == 0) {
        positions2[idx] = {process_pos.x + vel_new.x * dt, process_pos.y + vel_new.y * dt, process_pos.z + vel_new.z * dt};
        velocities2[idx] = vel_new;
    } else {
        positions[idx] = {process_pos.x + vel_new.x * dt, process_pos.y + vel_new.y * dt, process_pos.z + vel_new.z * dt};
        velocities[idx] = vel_new;
    }
}