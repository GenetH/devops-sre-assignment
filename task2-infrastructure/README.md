Task 2, Infrastructure (Ansible)
=================================

**Purpose:**
- This folder holds Ansible playbooks, roles, and an example inventory to set up and configure a small infrastructure stack, including a load balancer, web servers, and a database server.

**Layout (important files):**
- `ansible/site.yml` is the main playbook that combines roles.
- `ansible/inventory/hosts` is the primary inventory containing the `loadbalancer`, `webservers`, and `dbservers` groups.
- `ansible/inventory/testing/hosts` is an inventory for local or test runs (use this with care).
- `ansible/roles/` contains role implementations: `loadbalancer`, `webserver`, `mysqlserver`, `common`.
- `docker-compose.yml` is a convenience file (if available) to quickly set up local test nodes.

Prerequisites
- You need `ansible` (version 2.9 or higher is recommended) and `ansible-playbook` on your control machine.
- You must have `ssh` access to any real or test nodes (or use `ansible_connection=local` for localhost).
- Optional: `docker` and `docker-compose` or `multipass` if you want to create temporary test VMs or containers.

Quick testing options (pick one)
1) Local Docker-based test (fast, isolated)

- If you have `docker` and a `docker-compose.yml` in this folder, you can quickly start up test nodes:

```bash
# from the task2-infrastructure root
docker compose up -d
# wait until the containers are ready and can be accessed via SSH (check the compose file for service names and ports)
docker compose ps
- After the containers are ready, update `ansible/inventory/testing/hosts` with the container IPs or hostnames and SSH ports, or mount the inventory into the containers.

2) Multipass (recommended for lightweight VMs)
```bash
multipass launch --name lb1 --mem 1G --disk 5G 22.04
multipass launch --name web1 --mem 1G --disk 5G 22.04
multipass launch --name web2 --mem 1G --disk 5G 22.04
multipass launch --name db1 --mem 1G --disk 5G 22.04
multipass list    # note the IPs
```

- Edit `ansible/inventory/testing/hosts` and change the example `ansible_host` addresses to the IPs shown by `multipass list`.

3) Local-only (quick role development)
- For quick testing of role logic, such as file templates and idempotence, you can test against `localhost` by adding a `local` group that uses `ansible_connection=local` in the testing inventory.

Running the playbooks
---------------------

1) Dry-run (safe):

```bash
# run from the repository root
ansible-playbook -i ansible/inventory/testing/hosts ansible/site.yml --check --diff
```

Task 2, Infrastructure (Ansible)
=================================

Purpose
-------
This folder holds Ansible playbooks, roles, and an example inventory to set up and configure a small infrastructure stack, including a load balancer, web servers, and a database server.

Layout (important files)
------------------------
- `ansible/site.yml` is the main playbook that combines roles.
- `ansible/inventory/hosts` is the primary inventory containing the `loadbalancer`, `webservers`, and `dbservers` groups (do not change this for local testing).
- `ansible/inventory/testing/hosts` is an example local or test inventory. IMPORTANT: keep testing inventories local and do NOT push them to remote storage.
- `ansible/roles/` contains role implementations: `loadbalancer`, `webserver`, `mysqlserver`, `common`.
- `docker-compose.yml` is a convenience file (if available) to quickly set up local test nodes.

Prerequisites
-------------
- You need `ansible` (version 2.9 or higher is recommended) and `ansible-playbook` on your control machine.
- You must have `ssh` access to any real or test nodes (or use `ansible_connection=local` for localhost testing).
- Optional: `docker` and `docker-compose` or `multipass` if you want to create temporary test VMs or containers.

Important security and workflow note
----------------------------------
- The `ansible/inventory/testing/hosts` file is meant for local testing only and may include temporary IPs, ports, or keys. Do NOT commit or push this file to your Git remote. Treat any testing files containing credentials as secrets.
- To avoid accidental pushes, add a local-only inventory file to `.gitignore` (see example below) or keep testing inventories outside the repository and reference them with `-i` when running `ansible-playbook`.

Example `.gitignore` entry (local only)
```
# keep local testing inventories out of git
ansible/inventory/testing/
ansible/inventory/local_*.ini
```

Quick testing options (pick one)
--------------------------------
These options avoid changing the shared `ansible/inventory/hosts` and keep testing configurations local.

1) Local-only (fastest, safe)

- Create a small local inventory (outside source control) and run against `localhost` for templating and idempotence checks. For example, create a file `ansible/inventory/local_test.ini` (do not commit it):

```
[local]
localhost ansible_connection=local
```

- Run the playbook in dry-run mode, limited to the local inventory:

```bash
ansible-playbook -i ansible/inventory/local_test.ini ansible/site.yml --limit localhost --check --diff
```

2) Docker containers with SSH (isolated, repeatable)

- Use Docker images that support SSH (or build one) and map SSH ports to localhost. Update a local inventory (outside version control) to point to `127.0.0.1` with the mapped ports.

3) Multipass VMs (real VMs, isolated from CI/production)

- Launch lightweight VMs and update a local inventory file with the VMs' IPs. Do not commit the inventory file.

4) Molecule (role unit testing)

- Use `molecule` with the `docker` driver to run isolated role tests without altering shared inventories.

Running the playbooks (examples)
--------------------------------

Dry-run (safe, using local inventory):
```bash
ansible-playbook -i ansible/inventory/local_test.ini ansible/site.yml --check --diff
```

Targeted dry-run (limit to a host or group):
```bash
ansible-playbook -i ansible/inventory/local_test.ini ansible/site.yml --limit web1 --check --diff
```

Apply to test nodes (only when you are sure):
```bash
ansible-playbook -i ansible/inventory/local_test.ini ansible/site.yml
```

Validation and idempotence
-------------------------
- Run the same playbook on the same targets again. Ansible should report `ok` (no changes) for already-applied tasks. Unexpected `changed` results suggest non-idempotent tasks.
- Use `--diff` to preview changes to any templated files.

Debugging and common issues
---------------------------
- For SSH failures, ensure the `ansible_user` and SSH keys are correct in the inventory.
- Some tasks may need `become: true` for privilege escalation. Use `--ask-become-pass` or set up passwordless sudo for test VMs.
- To check for role template errors, run with `-vvv` for verbose output:

```bash
ansible-playbook -i ansible/inventory/local_test.ini ansible/site.yml -