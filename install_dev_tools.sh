#!/bin/bash

# Stop on errors.
set -e

DJANGO_VENV="${HOME}/.venvs/django"

Need_Docker=0
Need_Docker_Compose=0
Need_Python=0
Need_Pip=0
Need_VENV=0
Need_Django=0

PYTHON_BIN="python3"

check_software() {
    if command -v docker >/dev/null 2>&1; then
        echo "Docker is already installed."
    else
        echo "Docker is not installed."
        Need_Docker=1
    fi
    
    if docker compose version >/dev/null 2>&1; then
        echo "Docker Compose is already installed."
    else
        echo "Docker Compose is not installed."
        Need_Docker_Compose=1
    fi
    
    if command -v python3 >/dev/null 2>&1 && python3 -c 'import sys; exit(0 if sys.version_info >= (3, 9) else 1)'; then
        echo "Python 3.9 or newer is already installed: $(python3 --version)"
        
        if python3 -m pip --version >/dev/null 2>&1; then
            echo "pip is already installed."
        else
            echo "pip is not installed."
            Need_Pip=1
        fi
        
        if python3 -m venv -h >/dev/null 2>&1; then
            echo "venv is already installed."
        else
            echo "venv is not installed."
            Need_VENV=1
        fi
        
        if [[ -x "${DJANGO_VENV}/bin/python3" ]] && "${DJANGO_VENV}/bin/python3" -c "import django" >/dev/null 2>&1; then
            echo "Django is already installed: $("${DJANGO_VENV}/bin/python3" -c "import django; print(django.get_version())")"
        else
            echo "Django is not installed."
            Need_Django=1
        fi
    else
        echo "Python 3.9 or newer is not installed."
        Need_Python=1
        Need_Pip=1
        Need_VENV=1
        Need_Django=1
    fi
}

update_repo() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "Updating package repository..."
        sudo apt-get update -qq
    else
        echo "No supported package manager found. Please install apt-get."
        exit 1
    fi
}

prepare_docker_repo() {
    echo "Preparing Docker repository..."
    
    

    sudo apt-get update -qq
    sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release
    
    sudo install -m 0755 -d /etc/apt/keyrings

    sudo rm -f /etc/apt/keyrings/docker.gpg
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    
    sudo apt-get update -qq
}

install_docker() {
    echo "Installing Docker..."
    
    prepare_docker_repo
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io
    
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo "systemctl is not available. Cannot start/enable Docker service automatically."
        exit 1
    fi
}

install_docker_compose() {
    echo "Installing Docker Compose..."
    
    prepare_docker_repo
    sudo apt-get install -y -qq docker-compose-plugin
}

install_python() {
    
    
    echo "Installing Python 3.9..."
    
    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install -y python3.9  python3.9-venv python3-pip
    
    sudo ln -sf /usr/bin/python3.9 /usr/local/bin/python3
    hash -r
    
    
}

install_pip() {
    echo "Installing pip..."
    
    sudo apt-get install -y python3-pip
}

install_venv() {
    echo "Installing venv..."
    
    sudo apt-get install -y python3-venv
}

install_django() {
    echo "Installing Django..."
    
    if ! python3 -m pip --version >/dev/null 2>&1; then
        echo "pip is not installed. Installing pip before Django."
        install_pip
    fi
    
    if ! python3 -m venv -h >/dev/null 2>&1; then
        echo "venv is not installed. Installing venv before Django."
        install_venv
    fi
    
    python3 -m venv "$DJANGO_VENV"
    "${DJANGO_VENV}/bin/python3" -m pip install django
}

main() {
    check_software
    
    if [ "$Need_Docker" -eq 1 ] || [ "$Need_Docker_Compose" -eq 1 ] || [ "$Need_Python" -eq 1 ] || [ "$Need_Pip" -eq 1 ] || [ "$Need_Django" -eq 1 ] || [ "$Need_VENV" -eq 1 ]; then
        update_repo
        
        # Install dependencies in order.
        if [ "$Need_Python" -eq 1 ]; then
            echo "Installing Python."
            install_python
        else
            if [ "$Need_Pip" -eq 1 ]; then
                echo "Installing pip."
                install_pip
            fi
            
            if [ "$Need_VENV" -eq 1 ]; then
                echo "Installing venv before proceeding."
                install_venv
            fi
        fi
        
        if [ "$Need_Django" -eq 1 ]; then
            echo "Installing Django before proceeding."
            install_django
        fi
        
        if [ "$Need_Docker" -eq 1 ]; then
            echo "Installing Docker."
            install_docker
        fi
        
        if [ "$Need_Docker_Compose" -eq 1 ]; then
            echo "Installing Docker Compose."
            install_docker_compose
        fi
    else
        echo "All required software is already installed."
    fi
}

main "$@"