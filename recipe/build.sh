#! /usr/bin/bash
set -e

# The GitLab tarball doesn't include the yaml-cpp git submodule; use
# conda-forge's yaml-cpp instead of vendoring/building it
sed -i '/add_subdirectory( yaml-cpp )/d; /include_directories( yaml-cpp )/d' CMakeLists.txt
sed -i 's/find_package( ROOT /find_package( yaml-cpp REQUIRED )\nfind_package( ROOT /' CMakeLists.txt

# hep-forge's ROOT exports modern imported targets, not the legacy
# ROOT_INCLUDE_DIRS/ROOT_LIBRARIES variables this CMakeLists expects -- link
# against ROOT::* / yaml-cpp::yaml-cpp directly instead
ROOT_TARGETS="ROOT::Core ROOT::MathCore ROOT::RooFitCore ROOT::RooStats ROOT::Minuit2 ROOT::Graf ROOT::Hist ROOT::RIO ROOT::Tree ROOT::Gpad"
sed -i "s/target_link_libraries( Combiner yaml-cpp \${ROOT_LIBRARIES} )/target_link_libraries( Combiner yaml-cpp::yaml-cpp ${ROOT_TARGETS} )/" CMakeLists.txt
sed -i "s/target_link_libraries( \${name} Combiner yaml-cpp \${ROOT_LIBRARIES} )/target_link_libraries( \${name} Combiner yaml-cpp::yaml-cpp ${ROOT_TARGETS} )/" CMakeLists.txt
# ${ROOT_INCLUDE_DIRS} is now unset -- harmless, CMake treats it as empty

# CMakeLists.txt does `set( CMAKE_CXX_FLAGS "..." )`, which OVERWRITES
# CMAKE_CXX_FLAGS rather than appending -- environment CXXFLAGS gets wiped
# out, so patch ROOT's include dir directly into that set() call instead
ROOT_INCDIR="$(${PREFIX}/bin/root-config --incdir)"
sed -i "s|set( CMAKE_CXX_FLAGS \"-Wall -Wextra -Wshadow -pedantic -O2 -g -fPIC\" )|set( CMAKE_CXX_FLAGS \"-Wall -Wextra -Wshadow -pedantic -O2 -g -fPIC -I${ROOT_INCDIR}\" )|" CMakeLists.txt

cmake ${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX="${PREFIX}" -S . -B build

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu)
cmake --build build --parallel="${NPROC}"
cmake --install build
