SCD_DIR    := scd
ROFF_DIR   := man
HTML_DIR   := html
CSS_DIR    := css
OUTPUT_DIR := public

TEMPLATE_PAGE := $(HTML_DIR)/page.html

SCD_FILES  := $(wildcard $(SCD_DIR)/*.scd)
ROFF_FILES := $(patsubst $(SCD_DIR)/%.scd,$(ROFF_DIR)/%.roff,$(SCD_FILES))
HTML_FILES := $(patsubst $(ROFF_DIR)/%.roff,$(OUTPUT_DIR)/%.html,$(ROFF_FILES))

.PHONY: all clean roff build

all: build

roff: $(ROFF_FILES)
build: $(HTML_FILES)

clean:
	@rm -rf $(ROFF_DIR)
	@rm -rf $(OUTPUT_DIR)

$(ROFF_DIR)/%.roff: $(SCD_DIR)/%.scd | $(ROFF_DIR)
	@echo $@
	@scdoc < $< > $@

$(OUTPUT_DIR)/%.html: $(ROFF_DIR)/%.roff | $(OUTPUT_DIR)
	$(eval title := $(shell grep -A 2 '\.SH NAME' $< | tail -1))
	@echo $@
	@cp $(HTML_DIR)/index.html $(OUTPUT_DIR)/
	@cp $(CSS_DIR)/style.css $(OUTPUT_DIR)/
	# NOTE: The replacement of contiguous spaces must come _before_ the
	#       replacement of underlined text because otherwise the spacing
	#       between the section header and footer components will be shrunk.
	@nroff -man $< \
		| perl -pe 's/\x1b\[1m(.*?)\x1b\[(22|0)m/<b>\1<\/b>/gs' \
		| gsed -E -e 's/ +<\/b>/<\/b> /g' \
		| gsed -E -e 's/(,|\.|\?|\w) +(\w|<|[0-9])/\1 \2/g' \
		| perl -pe 's/\x1b\[4m(.*?)\x1b\[24m/<u>\1<\/u>/gs' \
		| gsed -E -e 's/<u>DANH\.COMPUTER<\/u>\(7\)/<a href="https:\/\/danh.computer">DANH.COMPUTER(7)<\/a>/g' \
		| gsed -E -e '/\{\{content\}\}/{r /dev/stdin' -e 'd;}' "$(TEMPLATE_PAGE)" \
		| gsed -E -e 's/\{\{title\}\}/${title}/' \
		> $@

$(ROFF_DIR):
	@mkdir -p $(ROFF_DIR)

$(OUTPUT_DIR): $(ROFF_DIR)
	@mkdir -p $(OUTPUT_DIR)

