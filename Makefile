.PHONY: help link-mysql unlink-mysql

SKILLS_CLI_DIR ?= ../skills-cli
SKILLS_MYSQL_DIR := skills/mysql
MYSQL_BIN := $(SKILLS_CLI_DIR)/bin/mysql

help:
	@echo "Available targets:"
	@echo "  link-mysql   - Create hard links from skills-cli/bin/mysql to skills/mysql/scripts/"
	@echo "  unlink-mysql - Restore original files in skills/mysql/scripts/"

link-mysql:
	@echo "Creating hard links..."
	@rm -rf $(SKILLS_MYSQL_DIR)/scripts
	@mkdir -p $(SKILLS_MYSQL_DIR)/scripts
	@ln $(MYSQL_BIN)/* $(SKILLS_MYSQL_DIR)/scripts/
	@echo "Done. Files are now hard linked to $(MYSQL_BIN)"

unlink-mysql:
	@echo "Restoring original files from git..."
	@git checkout -- $(SKILLS_MYSQL_DIR)/scripts/
	@echo "Done. Files are restored to original state"
