# Ansible Learning Lab Environment

This repository contains a Docker-based lab environment for learning Ansible, featuring multiple Linux distributions for hands-on practice.

## Installation

### Automatic Installation (Recommended)
```bash
# Make the setup script executable
chmod +x setup.sh

# Run the setup script
./setup.sh
```
The setup script will automatically:
- Detect your operating system
- Install all required dependencies
- Configure Docker and user permissions
- Install Ansible
- Create necessary directories

### Manual Installation

If you prefer to install manually, ensure you have the following installed on your system:

#### Required Software
- Docker (20.10.0 or newer)
- Docker Compose (v2.0.0 or newer)
- Python 3.8 or newer
- pip (Python package manager)
- SSH client

#### For macOS
```bash
# Install with Homebrew
brew install docker docker-compose python3 sshpass

# For Apple Silicon (M1/M2) Macs
# Docker Desktop for Apple Silicon is required
```

#### For Linux
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker.io docker-compose python3 python3-pip sshpass

# RHEL/CentOS/Rocky
sudo dnf install -y docker docker-compose python3 python3-pip sshpass
```

#### Install Ansible
```bash
# Install Ansible using pip
python3 -m pip install --user ansible

# Verify installation
ansible --version
```

## Quick Start

1. Clone the repository:
```bash
git clone <repository-url>
cd ansible-lab
```

2. Start the lab environment:
```bash
docker-compose up -d
```

3. Verify the setup:
```bash
ansible-playbook playbooks/test.yml
```

## Lab Environment Details

### Container Information
| Container | OS | SSH Port | Purpose |
|-----------|------|-----------|----------|
| Ubuntu | Ubuntu 22.04 | 2221 | Web Server |
| Rocky Linux | Rocky 8 | 2222 | Database Server |
| Debian | Debian 11 | 2223 | Web Server |
| Alpine | Alpine 3.18 | 2224 | Cache Server |

### Default Credentials
- Username: `ansible`
- Password: `ansible`
- SSH ports: 2221-2224
- Sudo access: Yes (passwordless)

### Directory Structure
```
ansible-lab/
├── docker/
│   ├── Dockerfile.ubuntu
│   ├── Dockerfile.centos
│   ├── Dockerfile.alpine
│   └── Dockerfile.debian
├── inventory/
│   ├── hosts
│   └── group_vars/
├── playbooks/
│   ├── setup.yml
│   └── test.yml
├── docker-compose.yml
├── ansible.cfg
└── README.md
```

## Usage Examples

### SSH into containers
```bash
# Ubuntu container
ssh ansible@localhost -p 2221

# Rocky Linux container
ssh ansible@localhost -p 2222

# Debian container
ssh ansible@localhost -p 2223

# Alpine container
ssh ansible@localhost -p 2224
```

### Run Ansible commands
```bash
# Ping all hosts
ansible all -m ping

# Get OS information
ansible all -m setup -a "filter=ansible_distribution*"

# Run playbook
ansible-playbook playbooks/test.yml
```

## Lab Management

### Start the lab
```bash
docker-compose up -d
```

### Stop the lab
```bash
docker-compose down
```

### Reset the lab
```bash
# Quick reset (preserves images)
docker-compose down
docker-compose up -d --build

# Full reset (rebuilds everything)
docker-compose down -v
docker system prune -af
docker-compose up -d --build
```

### View container logs
```bash
# All containers
docker-compose logs

# Specific container
docker-compose logs ubuntu
```

## Troubleshooting

### SSH Connection Issues
If you cannot SSH into containers:
1. Verify containers are running: `docker ps`
2. Check port mappings: `docker-compose ps`
3. Ensure sshpass is installed for password authentication
4. Verify no conflicting port usage: `netstat -tuln | grep '222'`

### Ansible Connection Issues
1. Check inventory file configuration
2. Verify SSH connectivity manually
3. Ensure Python is installed on target containers
4. Check Ansible configuration in ansible.cfg

### Common Issues and Solutions
1. Port conflicts: Change port mappings in docker-compose.yml
2. Permission issues: Ensure ansible user has sudo access
3. Python not found: All containers come with Python pre-installed
4. SSH key errors: Host key checking is disabled by default

## Learning Path

Follow the learning guide in `learning_guide.md` for:
1. Basic Ansible concepts
2. Playbook development
3. Role creation
4. Best practices
5. Advanced topics

## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 