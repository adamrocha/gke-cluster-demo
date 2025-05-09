# CONFIGURATION
SECRET_NAME = gke-private-key
KEY_FILE = /opt/keys/gke-private-key.pem
INVENTORY = ./inventory.gcp.yaml
ANSIBLE_USER = gke-user

.PHONY: all get-key ansible-ping

all: get-key ansible-ping

get-key:
	@echo "🔐 Retrieving SSH key from GCP Secret Manager..."
	gcloud secrets versions access latest --secret=$(SECRET_NAME) > $(KEY_FILE)
	chmod 600 $(KEY_FILE)
	@echo "✅ SSH key saved to $(KEY_FILE)"

ansible-ping:
	@echo "📡 Running Ansible ping test against GCP inventory..."
	ansible -i $(INVENTORY) all -u $(ANSIBLE_USER) --private-key=$(KEY_FILE) -m ping

clean:
	rm -f $(KEY_FILE)
