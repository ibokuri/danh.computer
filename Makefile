INPUT_DIR    := src
ROFF_DIR     := man
OUTPUT_DIR   := public
TEMPLATE_DIR := templates

TEMPLATE_PAGE := $(TEMPLATE_DIR)/page.html

SCD_FILES  := $(wildcard $(INPUT_DIR)/*.scd)
ROFF_FILES := $(patsubst $(INPUT_DIR)/%.scd,$(ROFF_DIR)/%.roff,$(SCD_FILES))
HTML_FILES := $(patsubst $(ROFF_DIR)/%.roff,$(OUTPUT_DIR)/%.html,$(ROFF_FILES))

.PHONY: all clean roff html

all: html

roff: $(ROFF_FILES)
html: $(HTML_FILES)

clean:
	@rm -rf $(ROFF_DIR)
	@rm -rf $(OUTPUT_DIR)

$(ROFF_DIR)/%.roff: $(INPUT_DIR)/%.scd | $(ROFF_DIR)
	@echo $@
	@scdoc < $< > $@

$(OUTPUT_DIR)/%.html: $(ROFF_DIR)/%.roff | $(OUTPUT_DIR)
	$(eval filename := $(basename $(notdir $@)))
	@echo $@
	@nroff -man $< \
		| gsed -E -e 's/(,|\.|,|\?|\w)  (\w)/\1 \2/g' \
		| perl -pe 's/\x1b\[1m(.*?)\x1b\[(22|0)m/<b>\1<\/b>/gs' \
		| gsed -E -e 's/ <\/b>/<\/b> /g' \
		| perl -pe 's/\x1b\[4m(.*?)\x1b\[24m/<u>\1<\/u>/gs' \
		| gsed -E -e 's/<u>DANH\.COMPUTER<\/u>\(7\)/<a href="https:\/\/danh.computer">DANH.COMPUTER(7)<\/a>/g' \
		| gsed -E -e '/\{\{content\}\}/{r /dev/stdin' -e 'd;}' "$(TEMPLATE_PAGE)" \
		| gsed -E -e 's/\{\{title\}\}/${filename}/' \
		> $@

$(ROFF_DIR):
	@mkdir -p $(ROFF_DIR)

$(OUTPUT_DIR): $(ROFF_DIR)
	@mkdir -p $(OUTPUT_DIR)

