# inventoryplay
Perl and ansible playbook to execute playbooks defined in the inventory
Python version is under construction...

# To execute all playbooks defined by the "install_playbooks" in inventory:

ansible-playbook  -i inventory/sample.ini inventoryplay.yml -e 'variable={{ install_playbooks }}'

# To execute all playbooks defined by the "config_playbooks" in inventory:

ansible-playbook  -i inventory/sample.ini inventoryplay.yml -e 'variable={{ config_playbooks }}'
