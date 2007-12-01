module bin;

import lib.foo;

int main()
{
    version (stupid) {
        return 0;
    } else {
        return lib.foo.bar();
    }
}
