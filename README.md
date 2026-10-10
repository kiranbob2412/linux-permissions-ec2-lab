# 🛡️ Linux File Permissions & AWS EC2 Shared Project Access

### Secure • Automated • Least Privilege • Production-Inspired

A practical Linux access-control automation project deployed on AWS EC2 using Bash, Linux users and groups, SGID permissions, POSIX ACLs, and SSH public-key authentication.

The objective is to provide controlled access to a shared project directory while ensuring that writers can collaborate and readers can access files without modifying them.

---

## 📌 Project Overview

In a multi-user Linux environment, every user should have only the permissions required to perform their assigned responsibilities.

This project implements role-based file access on an Ubuntu Linux server running on Amazon EC2.

A Bash automation script provisions Linux accounts, creates role-based groups, configures a shared directory, and applies traditional Linux permissions alongside POSIX Access Control Lists (ACLs).

### 🎯 Key Objectives

- Automate Linux user and group management.
- Configure secure shared-directory permissions.
- Separate writer and reader responsibilities.
- Implement the Principle of Least Privilege.
- Use SGID for shared group ownership.
- Configure POSIX ACLs and default ACL inheritance.
- Prepare user-specific SSH public-key authentication.
- Validate access restrictions through practical security tests.
- Demonstrate Linux administration skills relevant to AWS Cloud Engineering.

---

## 🏗️ System Architecture

The following diagram illustrates the logical architecture of the solution.

```text
                 ┌───────────────────────────┐
                 │     Cloud Administrator   │
                 │                           │
                 │  Local Ubuntu Workstation │
                 └─────────────┬─────────────┘
                               │
                               │ SSH / SCP
                               │ TCP Port 22
                               ▼
                 ┌───────────────────────────┐
                 │        AWS CLOUD          │
                 │                           │
                 │   Amazon EC2 Instance     │
                 │                           │
                 │     Ubuntu Linux          │
                 └─────────────┬─────────────┘
                               │
                               ▼
                 ┌───────────────────────────┐
                 │  setup-permissions.sh     │
                 │                           │
                 │  Bash Automation          │
                 └─────────────┬─────────────┘
                               │
               ┌───────────────┼────────────────┐
               │               │                │
               ▼               ▼                ▼
      ┌────────────────┐ ┌──────────────┐ ┌────────────────┐
      │ Linux Users    │ │ Linux Groups │ │ Access Control │
      │                │ │              │ │                │
      │ user01-user10  │ │ proj-writers │ │ POSIX ACLs     │
      │                │ │ proj-readers │ │ SGID           │
      └────────┬───────┘ └──────┬───────┘ └───────┬────────┘
               │                │                 │
               └────────────────┼─────────────────┘
                                │
                                ▼
                 ┌───────────────────────────┐
                 │       /srv/project        │
                 │                           │
                 │  Shared Project Directory │
                 │                           │
                 │  Owner: root              │
                 │  Group: proj-writers      │
                 │  Mode: 2770               │
                 └─────────────┬─────────────┘
                               │
                 ┌─────────────┴─────────────┐
                 │                           │
                 ▼                           ▼
       ┌──────────────────┐       ┌──────────────────┐
       │  WRITER ACCESS   │       │   READER ACCESS  │
       │                  │       │                  │
       │ user01           │       │ user04           │
       │ user02           │       │ user05           │
       │ user03           │       │ user06           │
       │                  │       │ user07            │
       │ Read + Write     │       │ user08            │
       │                  │       │ user09            │
       │                  │       │ user10            │
       │                  │       │ Read Only         │
       └──────────────────┘       └──────────────────┘
```

### 🧩 Architecture Components

| Component | Responsibility |
|---|---|
| AWS EC2 | Hosts the Ubuntu Linux server |
| Bash | Automates provisioning and permission configuration |
| Linux Users | Represent individual project users |
| Linux Groups | Organize users according to their responsibilities |
| SGID | Helps new files and directories inherit the shared directory's group |
| POSIX ACLs | Provide group-specific access permissions |
| SSH | Provides encrypted remote administration |
| `authorized_keys` | Stores authorized SSH public keys |
| `/srv/project` | Hosts shared project files |

---

## 👥 Role-Based Access Control

The project defines two distinct access roles.

### ✍️ 1. Writers

**Linux group:** `proj-writers`

| User | Role | Access |
|---|---|---|
| user01 | Writer | Read and write |
| user02 | Writer | Read and write |
| user03 | Writer | Read and write |

Writers can create files and directories, read shared content, and modify files when their effective permissions allow it.

### 📖 2. Readers

**Linux group:** `proj-readers`

| User | Role | Access |
|---|---|---|
| user04 | Reader | Read-only |
| user05 | Reader | Read-only |
| user06 | Reader | Read-only |
| user07 | Reader | Read-only |
| user08 | Reader | Read-only |
| user09 | Reader | Read-only |
| user10 | Reader | Read-only |

Readers can access and read authorized project content but cannot create files in the shared directory or modify existing files when the configured ACLs restrict write access.

### 🔒 Access Policy

| Operation | Writers | Readers | Others |
|---|---|---|---|
| List directory contents | Allowed | Allowed | Denied |
| Traverse the directory | Allowed | Allowed | Denied |
| Read authorized files | Allowed | Allowed | Denied |
| Create files | Allowed | Denied | Denied |
| Modify shared files | Allowed | Denied | Denied |
| Create subdirectories | Allowed | Denied | Denied |

**Security objective:** Apply the minimum permissions necessary for each role.

---

## ⚙️ Permission Model

The shared directory is configured with the following ownership and permission mode.

```text
Path:   /srv/project
Owner:  root
Group:  proj-writers
Mode:   2770
```

### 🔍 Understanding `2770`

| Component | Meaning |
|---|---|
| `2` | SGID bit |
| `7` | Owner: read, write, execute |
| `7` | Group: read, write, execute |
| `0` | Others: no permissions |

The SGID bit helps new files and directories inherit the parent directory's group ownership.

POSIX ACLs provide additional permissions for `proj-writers` and `proj-readers`.

### ACL Strategy

```text
Directory: /srv/project

Owner:
  root                         → rwx

Owning group:
  proj-writers                 → rwx

Additional group:
  proj-readers                 → r-x

ACL mask:
  rwx

Others:
  ---

Default ACLs:
  Writers                     → rwx
  Readers                     → r-x
  Others                      → ---
```

Effective permissions depend on the file or directory's actual mode, inherited ACLs, and ACL mask.

For regular files, execute permission is not automatically required or appropriate. Newly created files are normally readable and writable according to their creation mode and inherited ACLs.

---

## 🔄 End-to-End Deployment Workflow

The project follows a structured workflow from local development to remote configuration and verification.

```text
┌───────────────────────────────┐
│  1. LOCAL DEVELOPMENT         │
│                               │
│  Ubuntu Workstation            │
│  Create setup-permissions.sh  │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  2. STATIC VALIDATION          │
│                               │
│  bash -n                      │
│  Review script and permissions│
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  3. VERSION CONTROL            │
│                               │
│  Git repository                │
│  Commit project files          │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  4. GITHUB REPOSITORY          │
│                               │
│  Store source and documentation│
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  5. SECURE FILE TRANSFER       │
│                               │
│  SCP over SSH                  │
│  Upload to EC2                 │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  6. EC2 PRE-DEPLOYMENT CHECKS  │
│                               │
│  Verify instance and users     │
│  Review groups and directories │
│  Check script syntax           │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  7. CONFIGURATION              │
│                               │
│  Create users and groups       │
│  Configure /srv/project        │
│  Apply SGID and ACLs            │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  8. SECURITY VALIDATION        │
│                               │
│  Writer access tests           │
│  Reader access tests            │
│  Write-restriction tests        │
│  ACL inheritance tests          │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  9. FINAL VERIFICATION         │
│                               │
│  Inspect ownership and ACLs    │
│  Record test results            │
└───────────────────────────────┘
```

**Pipeline note:** This diagram describes the current manual operational workflow. A GitHub Actions CI/CD workflow is not included unless one is separately configured.

---

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| AWS EC2 | Cloud compute |
| Ubuntu Linux | Operating system |
| Bash | Automation |
| Linux Users and Groups | Identity and role management |
| `chmod` | Permission management |
| `chown` | Ownership management |
| SGID | Shared group inheritance |
| POSIX ACL | Fine-grained access control |
| `getfacl` | ACL inspection |
| `setfacl` | ACL configuration |
| SSH | Secure remote administration |
| SCP | Secure file transfer |
| Git | Version control |
| GitHub | Source-code hosting |

---

## 📋 Prerequisites

Before deployment, ensure that the following requirements are met.

- An AWS account with permission to manage EC2 resources.
- A dedicated Ubuntu EC2 lab instance.
- SSH access to the instance.
- A valid SSH private key stored securely on the administrator's workstation.
- The Bash shell.
- Sudo or root privileges for administrative setup.
- Network access for package installation when required.
- ACL utilities (`setfacl` and `getfacl`).

### 🔐 Security Group Requirements

Allow inbound TCP port `22` only from trusted administrator IP addresses.

Do not expose SSH to every IP address with `0.0.0.0/0` unless there is a specific, controlled requirement and suitable additional protections.

No HTTP or HTTPS rules are required for this permissions-only lab.

---

## 🚀 Installation and Deployment

### Step 1: Clone the repository

On the local Ubuntu workstation:

```bash
git clone https://github.com/kiranbob2412/linux-permissions-ec2-lab.git

cd linux-permissions-ec2-lab
```

### Step 2: Validate the setup script

```bash
bash -n setup-permissions.sh
```

No output generally indicates that Bash found no syntax errors.

This check does not prove that the script is free of runtime errors or security issues.

### Step 3: Upload the script to EC2

Replace the example path and IP with the actual values from your environment.

```bash
scp -i ~/Downloads/linux-permissions-key.pem \
setup-permissions.sh \
ubuntu@EC2_PUBLIC_IP:/home/ubuntu/
```

Do not include angle brackets around the actual IP address.

### Step 4: Connect to EC2

```bash
ssh -i ~/Downloads/linux-permissions-key.pem \
ubuntu@EC2_PUBLIC_IP
```

### Step 5: Review before execution

```bash
sudo bash -n ~/setup-permissions.sh

getent group proj-writers
getent group proj-readers

sudo ls -ld /srv/project 2>/dev/null || true
```

Review existing user accounts, group memberships, directory contents, ownership, and ACLs before proceeding.

**Important:** The setup script can modify ACLs recursively under `/srv/project`. Use a dedicated lab instance and avoid running it against existing production data without a reviewed change plan and backup.

### Step 6: Execute the setup

On the dedicated EC2 lab instance:

```bash
sudo bash ~/setup-permissions.sh
```

The setup script:

1. Checks for and installs ACL utilities when necessary.
2. Creates the writer and reader groups if absent.
3. Creates the configured user accounts if absent.
4. Adds each user to the appropriate role group.
5. Creates the shared project directory.
6. Sets directory ownership and SGID permissions.
7. Configures access ACLs and default ACLs.
8. Prints the resulting ACL configuration.

---

## 🧪 Validation and Testing

Testing is essential because a correctly executed configuration script does not automatically guarantee that every access policy works as intended.

Run the following checks on the EC2 server using an administrative account.

### Test 1: Verify groups

```bash
getent group proj-writers
getent group proj-readers
```

Expected membership:

- `proj-writers`: user01, user02, user03
- `proj-readers`: user04, user05, user06, user07, user08, user09, user10

### Test 2: Verify directory permissions

```bash
sudo ls -ld /srv/project

sudo getfacl -p /srv/project
```

Inspect ownership, SGID, access ACLs, and default ACLs.

### Test 3: Writer creates a file

```bash
sudo -u user01 sh -c \
'printf "Created by user01\n" > /srv/project/permission-test.txt'
```

Expected: the command succeeds.

### Test 4: Another writer updates the file

```bash
sudo -u user02 sh -c \
'printf "Updated by user02\n" >> /srv/project/permission-test.txt'
```

Expected: the command succeeds.

### Test 5: Reader reads the file

```bash
sudo -u user04 cat /srv/project/permission-test.txt
```

Expected content:

```text
Created by user01
Updated by user02
```

### Test 6: Reader cannot modify the file

```bash
if sudo -u user04 sh -c \
  'printf "Unauthorized change\n" >> /srv/project/permission-test.txt'
then
  echo "FAIL: Reader was able to write"
else
  echo "PASS: Reader write access denied"
fi
```

Expected:

```text
PASS: Reader write access denied
```

### Test 7: Reader cannot create a file

```bash
sudo -u user04 touch /srv/project/reader-test.txt
```

Expected: `Permission denied`.

This is the intended result because the reader role does not have write access to the shared directory.

### Test 8: Verify group ownership

```bash
sudo stat -c '%A %a %U:%G %n' \
/srv/project/permission-test.txt
```

Inspect the output to verify the file owner, group, mode, and ACL indicator.

### Test 9: Verify default ACL inheritance

Create a new directory as a writer:

```bash
sudo -u user01 mkdir /srv/project/team-a
```

Create a file inside it as another writer:

```bash
sudo -u user02 sh -c \
'printf "Default ACL inheritance test\n" > /srv/project/team-a/shared.txt'
```

Read it as a reader:

```bash
sudo -u user04 cat /srv/project/team-a/shared.txt
```

Inspect the inherited ACL:

```bash
sudo getfacl -p /srv/project/team-a/shared.txt
```

Expected policy:

- Writers have effective read/write access.
- Readers have effective read-only access.
- Others have no access.

If any test fails, inspect the ACL mask, inherited ACL entries, file creation mode, directory traversal permissions, and group membership before changing permissions.

---

## 🔑 SSH Public-Key Authentication

The setup script creates user-specific SSH directories and empty `authorized_keys` files.

These files must be populated with the corresponding users' **public keys** before those users can authenticate with SSH keys.

For example:

```text
/home/user01/.ssh/authorized_keys
/home/user02/.ssh/authorized_keys
/home/user03/.ssh/authorized_keys
```

### Recommended key security

- Use a separate SSH key pair for each person.
- Put only the public key in `authorized_keys`.
- Keep private keys securely on the authorized user's device.
- Never upload private keys to GitHub.
- Verify ownership and restrictive permissions on `.ssh` and `authorized_keys`.
- Do not grant users administrator privileges unless their responsibilities require it.

A Linux account being created does not, by itself, mean that SSH login has been fully configured and validated.

---

## 🛡️ Security Considerations

This project demonstrates several important Linux security practices.

### 1. Principle of Least Privilege

Each user receives permissions according to their assigned role.

### 2. Group-Based Administration

Users are managed through dedicated groups instead of manually assigning broad permissions to every account.

### 3. Restrictive Default Access

The shared directory prevents access by users outside the configured owner and group ACLs.

### 4. ACL Mask Awareness

The ACL mask limits the effective permissions of named-user and group ACL entries. Always inspect `getfacl` output when troubleshooting unexpected access.

### 5. SSH Key Protection

Private keys must remain confidential and should never be committed to Git.

### 6. Change Management

Before executing the setup against an existing directory, inspect the existing ACLs and ownership. Back up important data and review the impact of recursive permission changes.

### 7. Cloud Cost Control

AWS EC2 compute charges can apply while the instance is running. EBS storage and other associated resources may also incur charges. Review AWS pricing and remove lab resources when they are no longer needed.

---

## 🔧 Troubleshooting

| Symptom | Possible cause | Investigation |
|---|---|---|
| `Permission denied` on a writer operation | Missing group membership or ineffective ACL | Check `id`, `getfacl`, and directory traversal |
| Reader can write unexpectedly | Incorrect ACL mask or write permission | Inspect effective ACL permissions |
| Reader cannot read a file | Missing traversal or read permission | Check parent directories and file ACLs |
| New files have unexpected permissions | Default ACL or requested creation mode | Inspect default ACLs and the resulting file ACL |
| SSH public-key authentication fails | Incorrect public key, ownership, or permissions | Check `authorized_keys`, `.ssh` permissions, and SSH logs |
| `setfacl: command not found` | ACL utility unavailable | Install the appropriate ACL package |
| SCP cannot connect | Incorrect IP, network rule, or SSH availability | Verify EC2 state, current public IP, and TCP port 22 |

---

## 📈 Future Improvements

Potential enhancements include:

- A dedicated automated regression-test script.
- GitHub Actions for static validation and automated checks.
- Configuration-driven user and group definitions.
- A validation-only or dry-run mode.
- Structured setup logs and reports.
- Improved rollback and recovery procedures.
- Monitoring and audit-log integration.
- Infrastructure provisioning through Terraform.
- Integration with AWS Systems Manager for controlled administration.

These are future improvements unless separately implemented and tested.

---

## 🎓 Learning Outcomes

This project provides practical experience with:

- Linux user and group management.
- Numeric and symbolic file permissions.
- Ownership using `chown` and `chgrp`.
- SGID and shared directory design.
- POSIX access control lists.
- ACL masks and default ACL inheritance.
- SSH and SCP.
- Least-privilege access control.
- Bash automation.
- AWS EC2 Linux administration.
- Security validation and troubleshooting.
- Git and GitHub project management.

---

## ✅ Project Status

The following activities have been demonstrated during the lab:

- [x] Ubuntu EC2 instance provisioned.
- [x] Setup script transferred to EC2.
- [x] Writer and reader groups created.
- [x] Shared project directory configured.
- [x] Writer file-creation test passed.
- [x] Reader file-read test passed.
- [x] Reader write restriction test passed.
- [ ] Default ACL inheritance fully validated.
- [ ] All final regression tests documented.
- [ ] SSH login tested independently for every project user.
- [ ] GitHub publication completed and verified.

Only mark a pending item complete after its corresponding test has passed.

---

## 👨‍💻 Author

**Kiran Babu**

Cloud Engineering | AWS | Linux | Bash Automation | Security

GitHub Repository:

https://github.com/kiranbob2412/linux-permissions-ec2-lab

---

## ⭐ Key Takeaway

Secure shared storage is not just about changing file permissions. It requires a clear access model, correct group ownership, carefully configured ACLs, secure authentication, and repeatable verification.

This project demonstrates how Linux access-control fundamentals can be applied to a cloud-hosted server using AWS EC2 and Bash automation.
