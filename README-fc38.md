# Fedora Linux

## Preliminaries

Install an auxiliary helper tool:

    sudo dnf install python3-lit

Compile with `clang` instead of `gcc`:

    export CC=/usr/bin/clang
    export CXX=/usr/bin/clang++

## OMP

Edit the `configomp` script to:

+ use `llvm-config --version`.
+ use `tar -x --xz`.

Standard ways to add `-fPIC` to compilation all fail, because of the `configomp` script hack.
Modify the script to include `-DCMAKE_POSITION_INDEPENDENT_CODE=ON` on the `cmake` call.

## Math Kernel Library:

Add necessary lines from FAISS cmake configs to `CMakeLists.txt`.

Unsure if needed:
_(Compiling shows that FC38 uses [`flexiblas`](https://www.mpi-magdeburg.mpg.de/projects/flexiblas) libraries)_:

Install the math kernel library of choice, using instructions below:

### OpenBLAS

    sudo dnf install openblas-devel

### Intel

Create the `/etc/yum.repos.d/oneAPI.repo` according to the instructions by the
[Intel install docs](https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html?operatingsystem=linux&distributions=dnf).

Install the base toolkit:

    sudo dnf install intel-basekit

For more info, refer to Intel's 
[oneAPI Math Kernel Library](https://www.intel.com/content/www/us/en/docs/onemkl/developer-reference-dpcpp/2023-1/overview.html).
