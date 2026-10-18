#include <stdio.h>
#include <stdlib.h>

int main() {
    int var_stack;
    void *var_heap = malloc(10);
    printf("Executable (main): %p\n", main);
    printf("Stack: %p\n", &var_stack);
    printf("Heap: %p\n", var_heap);
    printf("Shared Library (printf): %p\n", printf);
    return 0;
}
