.PHONY: policy policy-report bootstrap depgraph ccdb autoupdate sync doctor \
        git-init secrets cruft cruft-untrack cruft-preview inspect inspect-all \
        inspect-code inspect-changed inspect-diff inspect-wt inspect-wt-all \
        inspect-wt-code

# Full scan: default + manual stages; fail once at the end
policy:
	@bash -lc 'rc=0; \
	  pre-commit run --all-files || rc=1; \
	  pre-commit run --all-files --hook-stage manual || rc=1; \
	  exit $$rc'

# Non-blocking report (always exit 0)
policy-report:
	@pre-commit run --all-files || true
	@pre-commit run --all-files --hook-stage manual || true
	@echo "Policy report complete (non-blocking)."

bootstrap: ; @bash tool/bootstrap.sh
depgraph:  ; @bash tool/depgraph.sh
ccdb:      ; @bash tool/gen_compile_db.sh
sync:      ; @bash -lc 'bash tool/sync_policies.sh --check || (bash tool/sync_policies.sh && echo "updated .clang-tidy from budgets")'
doctor:    ; @bash tool/policy_doctor.sh

git-init:
	@if [ ! -d .git ]; then git init && git add . && git commit -m "chore: init repo"; else echo "Already a Git repo."; fi

secrets: ; @bash -lc 'detect-secrets scan --exclude-files "(\\.git|build|external)/" > .secrets.baseline && git add .secrets.baseline && echo "Updated .secrets.baseline"'

cruft-preview:  ; @bash tool/cruft_sweeper.sh --preview
cruft:          ; @bash tool/cruft_sweeper.sh --delete
cruft-untrack:  ; @bash tool/cruft_sweeper.sh --untrack

inspect:         ; @bash tool/inspect_configs.sh curated
inspect-all:     ; @bash tool/inspect_configs.sh all
inspect-code:    ; @bash tool/inspect_configs.sh code
inspect-changed: ; @bash tool/inspect_configs.sh diff
inspect-wt:      ; @bash tool/inspect_configs.sh wt
inspect-wt-all:  ; @bash tool/inspect_configs.sh wt-all
inspect-wt-code: ; @bash tool/inspect_configs.sh wt-code

inspect-diff:
	@files=$$(git diff --name-only HEAD); if [ -n "$$files" ]; then git --no-pager diff -- $$files; else echo "No changes vs HEAD"; fi

autoupdate: ; @bash -lc 'pre-commit autoupdate && git diff -- .pre-commit-config.yaml'
