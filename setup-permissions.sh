#!/usr/bin/env bash
# Run on a dedicated EC2 lab instance:
# sudo bash setup-permissions.sh

set -Eeuo pipefail

PROJECT_DIR="/srv/project"

WRITERS_GROUP="proj-writers"
READERS_GROUP="proj-readers"

WRITERS=(user01 user02 user03)
READERS=(user04 user05 user06 user07 user08 user09 user10)

# Require root privileges.
if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    exit 1
fi

# Install ACL utilities if needed.
if ! command -v setfacl >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y acl
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y acl
    elif command -v yum >/dev/null 2>&1; then
        yum install -y acl
    else
        echo "ERROR: No supported package manager found."
        exit 1
    fi
fi

# Create groups only when absent.
getent group "$WRITERS_GROUP" >/dev/null ||
    groupadd "$WRITERS_GROUP"

getent group "$READERS_GROUP" >/dev/null ||
    groupadd "$READERS_GROUP"

# Create or configure users.
create_user() {
    local username="$1"
    local groupname="$2"

    if ! id "$username" >/dev/null 2>&1; then
        useradd -m -s /bin/bash "$username"
    fi

    usermod -aG "$groupname" "$username"

    install -d \
        -m 700 \
        -o "$username" \
        -g "$username" \
        "/home/$username/.ssh"

    touch "/home/$username/.ssh/authorized_keys"

    chmod 600 "/home/$username/.ssh/authorized_keys"

    chown "$username:$username" \
        "/home/$username/.ssh/authorized_keys"
}

for username in "${WRITERS[@]}"; do
    create_user "$username" "$WRITERS_GROUP"
done

for username in "${READERS[@]}"; do
    create_user "$username" "$READERS_GROUP"
done

# Create the shared project directory.
install -d -m 2770 "$PROJECT_DIR"

chown "root:$WRITERS_GROUP" "$PROJECT_DIR"

chmod 2770 "$PROJECT_DIR"

# Configure access ACLs.
# Capital X adds execute only to directories and
# to files that already have at least one execute bit.
setfacl -R \
    -m "g:${WRITERS_GROUP}:rwX,g:${READERS_GROUP}:r-X,m::rwx" \
    "$PROJECT_DIR"

# Configure default ACLs on directories only.
find "$PROJECT_DIR" -type d \
    -exec setfacl \
        -m "d:g:${WRITERS_GROUP}:rwx,d:g:${READERS_GROUP}:r-x,d:m::rwx" \
        {} +

echo
echo "=== Setup completed ==="

echo
echo "Project directory:"
ls -ld "$PROJECT_DIR"

echo
echo "ACL configuration:"
getfacl "$PROJECT_DIR"

echo
echo "Writer group:"
getent group "$WRITERS_GROUP"

echo
echo "Reader group:"
getent group "$READERS_GROUP"

echo
echo "IMPORTANT:"
echo "Add each authorized user's SSH public key"
echo "to that user's authorized_keys file."
