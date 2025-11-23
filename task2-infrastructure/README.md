# Task 2, Infrastructure (Ansible)

Purpose  
-------  
This folder has Ansible playbooks, roles, and a sample inventory to set up and configure a small infrastructure stack, which includes a load balancer, web servers, and a database server.

Layout (important files)  
------------------------  
- `ansible/site.yml` is the main playbook that puts together roles.  
- `ansible/inventory/hosts` is the main inventory with groups for `loadbalancer`, `webservers`, and `dbservers` (do not change this for shared or production use).  
- `ansible/roles/` holds the role implementations: `loadbalancer`, `webserver`, `mysqlserver`, `common`.  
- `ansible/ansible.cfg` is the recommended Ansible configuration for runs in this repository.  
- Role templates are under `ansible/roles/*/templates`.  

Note: this repository does not include an `ansible/inventory/` folder. See "Quick testing" below for safe alternatives.  

Prerequisites  
-------------  
- Ansible (version 2.9 or higher recommended) installed on your control machine.  
- SSH access to target hosts (or use `ansible_connection=local` for localhost).  
- Optional: Docker or docker-compose for temporary test hosts.  
- Keep sensitive information encrypted with Ansible Vault or a secret manager; do not commit any credentials.  

Important security and workflow note  
---------------------------------  
- Keep any local or testing inventories, private keys, or credentials out of version control systems.  
- Create local inventory files outside the repository or add them to `.gitignore`.  
- Example `.gitignore` entries (add to the repository if needed):  
  ```  
  ansible/inventory/local_*.ini  
  ansible/vault_secrets.yml  
  ```  

4) Molecule (role unit testing)  
- If you use Molecule, run isolated role tests with the `docker` driver. This allows for unit testing roles without affecting shared inventories.  

Running the playbooks  
---------------------  
- Syntax check:  
  ```bash  
  ansible-playbook -i ansible/inventory/hosts ansible/site.yml --syntax-check  
  ```  
- Apply to inventory (be careful; this will make changes):  
  ```bash  
  ansible-playbook -i ansible/inventory/hosts ansible/site.yml  
  ```  

Debugging  
---------  
- Increase verbosity to check for failures:  
  ```bash  
  ansible-playbook -i /path/to/local_test.ini ansible/site.yml -l web1 -vvv  
  ```  

- Confirm SSH connectivity:  
  ```bash  
  ansible -i ansible/inventory/hosts all -m ping  
  ```  

Cleanup examples  
----------------  
- Docker Compose (if you used it for test containers):  
  ```bash  
  docker compose down --volumes  
  ``` 
CI and validation suggestions  
---------------------------  
- Add checks for continuous integration:  
  - `ansible-lint` for roles and playbooks  
  - `yamllint` for YAML quality  
  - `ansible-playbook --syntax-check` and `--check` against a disposable test inventory  
 