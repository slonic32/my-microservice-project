#! /bin/bash

DJANGO_VENV="${HOME}/.venvs/django"

Need_Docker=0
Need_Docker_Compose=0
Need_Python=0
Need_Pip=0
Need_VENV=0
Need_Ensurepip=0
Need_Django=0

check_software() {
  if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed."
  else
    echo "Docker is not installed."
    Need_Docker=1
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose is already installed."
  else
    echo "Docker Compose is not installed."
    Need_Docker_Compose=1
  fi

  if command -v python3 >/dev/null 2>&1; then
    echo "Python is already installed."
  else
    echo "Python is not installed."
    Need_Python=1
  fi

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

  if python3 -m ensurepip --version >/dev/null 2>&1; then
    echo "ensurepip is already installed."
  else
    echo "ensurepip is not installed."
    Need_Ensurepip=1
  fi

  if [[ -x "${DJANGO_VENV}/bin/python3" ]] && "${DJANGO_VENV}/bin/python3" -m django --version >/dev/null 2>&1; then
    echo "Django is already installed."
  else
    echo "Django is not installed."
    Need_Django=1
  fi
}

update_repo() {
  if command -v apt >/dev/null 2>&1; then
    echo "Updating package repository..."
    sudo apt-get update

  else
    echo "No supported package manager found. Please install apt."
  fi

}

install_docker() {
  echo "Installing Docker..."

  sudo apt-get install -y docker-cli
}

install_docker_compose() {
  echo "Installing Docker Compose..."

  sudo apt-get install -y docker-compose
}

install_python() {
  echo "Installing Python and pip..."

  sudo apt-get install -y python3
}

install_pip() {
  echo "Installing pip..."

  sudo apt-get install -y python3-pip
}

install_venv() {
  echo "Installing venv..."

  sudo apt-get install -y python3-venv
}

install_ensurepip() {
  echo "Installing ensurepip..."

  sudo apt-get install -y python3-venv
}

install_django() {
  echo "Installing Django..."

  python3 -m venv "$DJANGO_VENV"
  source "$DJANGO_VENV/bin/activate"

  python3 -m pip install django
}

main() {
  check_software

  if [ $Need_Docker -eq 1 ] || [ $Need_Docker_Compose -eq 1 ] || [ $Need_Python -eq 1 ] || [ $Need_Pip -eq 1 ] || [ $Need_Django -eq 1 ] || [ $Need_VENV -eq 1 ] || [ $Need_Ensurepip -eq 1 ]; then
    update_repo
    if [ $Need_Docker -eq 1 ]; then
      echo "Installing Docker."
      install_docker
    fi

    if [ $Need_Docker_Compose -eq 1 ]; then
      echo "Installing Docker Compose."
      install_docker_compose
    fi

    if [ $Need_Python -eq 1 ]; then
      echo "Installing Python."
      install_python

    fi

    if [ $Need_Pip -eq 1 ]; then
      echo "Installing pip."
      install_pip

    fi

    if [ $Need_VENV -eq 1 ]; then
      echo "Installing venv before proceeding."
      install_venv
    fi

    if [ $Need_Ensurepip -eq 1 ]; then
      echo "Installing ensurepip before proceeding."
      install_ensurepip
    fi

    if [ $Need_Django -eq 1 ]; then
      echo "Installing Django before proceeding."
      install_django
    fi

  else
    echo "All required software is already installed."

  fi

}

main "$@"
