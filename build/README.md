
# Reproducible Canister Builds
For more information, see this [page](https://internetcomputer.org/docs/current/developer-docs/backend/reproducible-builds) on DFINITY.
## Setup Container
if you are using Apple silicon Mac, you need to install lima in order to build on x86_64.  
if you are using Intel chip Mac or WSL or Linuc, skip to [[🛠 Make alias]](#🛠-make-alias)

### 🛠 Install Lima
[lima](https://github.com/lima-vm/lima)

```bash
cd <PROJECT ROOT>
```

```bash
brew install lima
```
---
### 🛠 Make Lima Instance
```bash
limactl start build/intel_on_arm_with_nerdctl.yaml
```
select `Open an editor to review or modify the current configuration` and edit mount location(line52,59)
```diff
mounts:
- - location: "~"
-   writable: null

+ - location: "<Your Project Root Absolute Path>"
+   writable: true
```
setup nerdctl 
```bash
build/setup_nerdctl.sh
```
---
### 🛠 Make Alias
For Apple silicon Mac 🍎
```bash
alias build_image="limactl shell intel_on_arm_with_nerdctl nerdctl build --platform=amd64 -t reproducible_kindb_builds build/"

alias run_compile="limactl shell intel_on_arm_with_nerdctl nerdctl run --platform=amd64 --rm \
                    -v $(pwd)/src/canisters:/project_root/canisters \
                    -v $(pwd)/build:/project_root/build \
                    -v $(pwd)/vessel.dhall:/project_root/vessel.dhall \
                    -v $(pwd)/package-set.dhall:/project_root/package-set.dhall \
                    reproducible_kindb_builds \
                    bash ./build/build.sh"

alias run_reprotest="limactl shell intel_on_arm_with_nerdctl nerdctl run --platform=amd64 --rm --privileged \
                    -v $(pwd)/src/canisters:/project_root/canisters \
                    -v $(pwd)/build:/project_root/build \
                    -v $(pwd)/vessel.dhall:/project_root/vessel.dhall \
                    -v $(pwd)/package-set.dhall:/project_root/package-set.dhall \
                    reproducible_kindb_builds \
                    bash ./build/reprotest.sh"
```

For Intel chip 🖥 
```bash
alias build_image="docker build -t reproducible_kindb_builds build/"

alias run_compile="docker run --rm \
                    -v $(pwd)/src/canisters:/project_root/canisters \
                    -v $(pwd)/build:/project_root/build \
                    -v $(pwd)/vessel.dhall:/project_root/vessel.dhall \
                    -v $(pwd)/package-set.dhall:/project_root/package-set.dhall \
                    reproducible_kindb_builds \
                    bash ./build/build.sh"

alias run_reprotest="docker run --rm --privileged \
                    -v $(pwd)/src/canisters:/project_root/canisters \
                    -v $(pwd)/build:/project_root/build \
                    -v $(pwd)/vessel.dhall:/project_root/vessel.dhall \
                    -v $(pwd)/package-set.dhall:/project_root/package-set.dhall \
                    reproducible_kindb_builds \
                    bash ./build/reprotest.sh"
```
---
## Reproducible Build
### 🛠 Build Wasm Binary
```bash
build_image
```
```bash
run_compile
```
you can check the binaries in `build/outputs/` directory.

if you want to check [reprotest](https://salsa.debian.org/reproducible-builds/reprotest), run this command
```bash
run_reprotest
```
then it returns somthing like this
```
=======================
Reproduction successful
=======================
No differences in ./build/outputs/*.wasm
1b470d85643da52f6d1adbcd75fc2b37b61c22d688e1737a993d9e02ca05db03  ./build/outputs/candb_index.wasm
86202ae0e7f5f4c80136cb956837e8edaa0e97cd95f09621b243014f481c266a  ./build/outputs/candb_service.wasm
```
---
### 🛠 Restart Lima Instance
Once the container image and lima instance have been created, you can be reused even if the code changes.
show current lima instance
```bash
limactl list
```
stop instance
```bash
limactl stop intel_on_arm_with_nerdctl
```
restart instance
```bash
limactl start intel_on_arm_with_nerdctl
./build/setup_nerdctl.sh
```
---
### 🛠 Enter Shell
you can also enter the instance
```bash
limactl shell intel_on_arm_with_nerdctl
```
if you want to enter the container
```bash
limactl limactl shell intel_on_arm_with_nerdctl nerdctl run -it --platform=amd64 --rm \
  -v $(pwd)/src/canisters:/project_root/canisters \
  -v $(pwd)/build:/project_root/build \
  -v $(pwd)/vessel.dhall:/project_root/vessel.dhall \
  -v $(pwd)/package-set.dhall:/project_root/package-set.dhall \
  reproducible_kindb_builds
```