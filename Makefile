# Supabase Easy - Makefile
# Automated setup for self-hosted Supabase that actually works

.PHONY: help install download clean stop restart logs status uninstall install-minimal verify update

# Configuration
PROJECT ?= supabase-local
PORT ?= 8000
CACHE_DIR := cache
PROJECTS_DIR := projects
SCRIPTS_DIR := scripts

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "Supabase Easy - Self-hosting made simple"
	@echo ""
	@echo "Usage: make [target] [VARIABLE=value]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  ${GREEN}%-15s${NC} %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables:"
	@echo "  ${YELLOW}PROJECT${NC}   Project name (default: supabase-local)"
	@echo "  ${YELLOW}PORT${NC}      API port (default: 8000)"
	@echo ""
	@echo "Examples:"
	@echo "  make install                    # Basic installation"
	@echo "  make install PROJECT=myapp      # Custom project name"
	@echo "  make install PORT=8001          # Different port"

install: download ## Install Supabase with all fixes applied
	@echo "${GREEN}🚀 Installing Supabase Easy - Project: $(PROJECT)${NC}"
	@mkdir -p $(PROJECTS_DIR)/$(PROJECT)
	@echo "📋 Copying files to project..."
	@cp -r $(CACHE_DIR)/docker/* $(PROJECTS_DIR)/$(PROJECT)/
	@cp $(CACHE_DIR)/docker/.env.example $(PROJECTS_DIR)/$(PROJECT)/.env
	@echo "🔧 Applying fixes..."
	@bash $(SCRIPTS_DIR)/fix-issues.sh $(PROJECTS_DIR)/$(PROJECT)
	@echo "🚀 Starting services..."
	@cd $(PROJECTS_DIR)/$(PROJECT) && docker-compose up -d db vector imgproxy
	@echo "⏳ Waiting for database (30 seconds)..."
	@sleep 30
	@cd $(PROJECTS_DIR)/$(PROJECT) && docker exec $$(docker-compose ps -q db) psql -U postgres -c "CREATE DATABASE _supabase;" 2>/dev/null || true
	@cd $(PROJECTS_DIR)/$(PROJECT) && docker-compose up -d analytics
	@echo "⏳ Waiting for analytics (20 seconds)..."
	@sleep 20
	@cd $(PROJECTS_DIR)/$(PROJECT) && docker-compose up -d
	@echo "⏳ Waiting for all services (45 seconds)..."
	@sleep 45
	@make verify PROJECT=$(PROJECT)
	@echo ""
	@echo "${GREEN}✅ Supabase is ready!${NC}"
	@echo ""
	@echo "📌 Access at: http://localhost:$(PORT)"
	@echo "👤 Username: supabase"
	@echo "🔑 Password: this_password_is_insecure_and_should_be_updated"
	@echo ""
	@echo "📁 Project location: $(PROJECTS_DIR)/$(PROJECT)"

download: ## Download required files from Supabase (cached)
	@echo "${YELLOW}📦 Downloading Supabase files...${NC}"
	@bash $(SCRIPTS_DIR)/download.sh $(CACHE_DIR)
	@echo "${GREEN}✅ Files cached in: $(CACHE_DIR)${NC}"

clean: ## Clean project directory
	@echo "${YELLOW}🧹 Cleaning project: $(PROJECT)${NC}"
	@if [ -d "$(PROJECTS_DIR)/$(PROJECT)" ]; then \
		cd $(PROJECTS_DIR)/$(PROJECT) && docker-compose down -v 2>/dev/null || true; \
		rm -rf $(PROJECTS_DIR)/$(PROJECT)/volumes; \
	fi
	@echo "${GREEN}✅ Project cleaned${NC}"

stop: ## Stop Supabase services
	@echo "${YELLOW}⏹️  Stopping project: $(PROJECT)${NC}"
	@cd $(PROJECTS_DIR)/$(PROJECT) && docker-compose down
	@echo "${GREEN}✅ Services stopped${NC}"

restart: ## Restart Supabase services
	@echo "${YELLOW}🔄 Restarting project: $(PROJECT)${NC}"
	@cd $(PROJECTS_DIR)/$(PROJECT) && docker-compose restart
	@echo "${GREEN}✅ Services restarted${NC}"

logs: ## View logs (use SERVICE=name for specific service)
	@if [ -z "$(SERVICE)" ]; then \
		cd $(PROJECTS_DIR)/$(PROJECT) && docker-compose logs -f; \
	else \
		cd $(PROJECTS_DIR)/$(PROJECT) && docker-compose logs -f $(SERVICE); \
	fi

status: ## Show status of all services
	@echo "${YELLOW}📊 Status for project: $(PROJECT)${NC}"
	@cd $(PROJECTS_DIR)/$(PROJECT) && docker-compose ps

verify: ## Verify installation is working
	@echo "${YELLOW}🔍 Verifying installation...${NC}"
	@bash $(SCRIPTS_DIR)/verify.sh $(PROJECTS_DIR)/$(PROJECT)

uninstall: clean ## Completely remove project and data
	@echo "${RED}⚠️  Uninstalling project: $(PROJECT)${NC}"
	@echo "This will delete all data. Continue? [y/N]"
	@read -r response; \
	if [ "$$response" = "y" ]; then \
		rm -rf $(PROJECTS_DIR)/$(PROJECT); \
		echo "${GREEN}✅ Project uninstalled${NC}"; \
	else \
		echo "Cancelled"; \
	fi

install-minimal: download ## Install without analytics (simpler, more stable)
	@echo "${GREEN}🚀 Installing Supabase Minimal - Project: $(PROJECT)${NC}"
	@mkdir -p $(PROJECTS_DIR)/$(PROJECT)
	@cp -r $(CACHE_DIR)/docker/* $(PROJECTS_DIR)/$(PROJECT)/
	@cp $(CACHE_DIR)/docker/.env.example $(PROJECTS_DIR)/$(PROJECT)/.env
	@bash $(SCRIPTS_DIR)/fix-issues.sh $(PROJECTS_DIR)/$(PROJECT)
	@echo "📝 Disabling analytics dependencies..."
	@bash $(SCRIPTS_DIR)/remove-analytics.sh $(PROJECTS_DIR)/$(PROJECT)
	@cd $(PROJECTS_DIR)/$(PROJECT) && docker-compose up -d db kong auth rest storage meta studio imgproxy
	@echo "${GREEN}✅ Minimal Supabase ready at: http://localhost:$(PORT)${NC}"

update: ## Update cached files from latest Supabase
	@echo "${YELLOW}🔄 Updating from latest Supabase...${NC}"
	@rm -rf $(CACHE_DIR)
	@make download
	@echo "${GREEN}✅ Cache updated with latest files${NC}"

list: ## List all projects
	@echo "${YELLOW}📋 Installed projects:${NC}"
	@if [ -d "$(PROJECTS_DIR)" ]; then \
		ls -1 $(PROJECTS_DIR) | sed 's/^/  • /'; \
	else \
		echo "  No projects found"; \
	fi

# Default target
.DEFAULT_GOAL := help