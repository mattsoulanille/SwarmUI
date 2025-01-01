#!/usr/bin/env bash

# Check if GPU type is provided
if [ $# -eq 0 ]; then
    echo "Error: GPU type not specified. Please use 'amd' or 'nv' as an argument."
    exit 1
fi

GPU_TYPE=$1

# Validate GPU type
if [ "$GPU_TYPE" != "amd" ] && [ "$GPU_TYPE" != "nv" ]; then
    echo "Error: Invalid GPU type. Please use 'amd' or 'nv'."
    exit 1
fi

mkdir dlbackend

cd dlbackend

git clone https://github.com/comfyanonymous/ComfyUI

cd ComfyUI

# Try to find a good python executable, and dodge unsupported python versions
for pyvers in python3.11 python3.10 python3.12 python3 python
do
    python=`which $pyvers`
    if [ "$python" != "" ]; then
        break
    fi
done
if [ "$python" == "" ]; then
    >&2 echo ERROR: cannot find python3
    >&2 echo Please follow the install instructions in the readme!
    exit 1
fi

# Validate venv
venv=`$python -m venv 2>&1`
case $venv in
    *usage*)
        :
    ;;
    *)
        >&2 echo ERROR: python venv is not installed
        >&2 echo Please follow the install instructions in the readme!
        >&2 echo If on Ubuntu/Debian, you may need: sudo apt install python3-venv
        exit 1
    ;;
esac

# Make and activate the venv. "python3" in the venv is now the python executable.
if [ -z "${SWARM_NO_VENV}" ]; then
    $python -s -m venv venv
    source venv/bin/activate
    python=python3
fi

# Install PyTorch based on GPU type
if [ "$GPU_TYPE" == "nv" ]; then
    $python -s -m pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124
elif [ "$GPU_TYPE" == "amd" ]; then
    $python -s -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1
fi

echo "Replacing torch with one that works on gh200 machines"
NEW_URL="https://drive.usercontent.google.com/download?id=1MDNtLcc7vw94P2oqa5Ub1Uk_JAmePHOI&export=download&authuser=0&confirm=t&uuid=f0ddb3b8-d868-43d5-9493-230753aa0047&at=APvzH3pjwCkX5b_3N8z2Lstdky7-%3A1735704293904"
TORCH_WHL="torch-2.6.0.dev20241231+cu126-cp311-cp311-linux_aarch64.whl"
curl ${NEW_URL} > ${TORCH_WHL}

sed -i.bak "s/^torch$/${TORCH_WHL}/g" requirements.txt
$python -s -m pip install -r requirements.txt

echo "Installation completed for $GPU_TYPE GPU."
