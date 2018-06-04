#!/bin/bash

. ./init.sh

inventory=${INVENTORY:-${INVENTORY_DIR}/inventory}
ansible_playbook ${inventory} ${PLAYBOOKS_DIR}/deploy-local.yml "$@"
