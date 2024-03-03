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
	@echo $@
	@cp $(HTML_DIR)/index.html $(OUTPUT_DIR)/
	@cp $(CSS_DIR)/style.css $(OUTPUT_DIR)/
# The following command obtains the text underneath the NAME section in the
# current ROFF file. It'll be used as the <title> for the final HTML file.
	$(eval title := $(shell grep -A 2 '\.SH NAME' $< | tail -1))
# The following command converts a ROFF file into HTML.
#
#   1. Replace *bold* escape sequences with their HTML equivalent.
#
#   2. Fix spacing for resulting </b> tags. There might be extra spaces
#      before the tag and no space after it due to how nroff positions the
#      escape sequences.
#
#   3. Condense contiguous space characters after ',', '.', '?', and words
#      into a single space. In order to fully justify the text, nroff adds
#      additional spaces sometimes, so those extra spaces are removed here.
#
#   4. Replace *underline* escape sequences with their HTML equivalent.
#
#   5. Make the left and right section headers and footer links to the home
#      page. Note that this must be done _after_ extraneous spaces are
#      condensed. Otherwise, the spacing before the right header and footer
#      text will be incorrect.
#
#   6. Replace '{{content}}' in the page template with the man page.
#
#   7. Replace '{{title}}' in the page template with the man page's name.
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

