#ifndef NBODY_BINTRIE_NODES_H
#define NBODY_BINTRIE_NODES_H

struct RadixTreeInternal {
    int32_t left_child;
    int32_t right_child;
    int32_t parent;
    int32_t range_first;
    int32_t range_last;
};

#endif //NBODY_BINTRIE_NODES_H
