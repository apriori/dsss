/*
 * Dynamic module loader for Posix
 * Simply a constructor that calls _dy_moduleCtor()
 */

void _dy_moduleCtor();

__attribute__((constructor)) void dyloadposix() {
    _dy_moduleCtor();
}
