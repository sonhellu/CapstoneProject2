# Luôn chạy codegen l10n trước analyze/test để tránh thiếu lib/l10n/*.dart.
.PHONY: gen-l10n analyze test
gen-l10n:
	flutter gen-l10n

analyze: gen-l10n
	flutter analyze

test: gen-l10n
	flutter test
