SCD_DIR    := scd
ROFF_DIR   := man
HTML_DIR   := html
CSS_DIR    := css
OUTPUT_DIR := public

TEMPLATE_FILE := $(HTML_DIR)/template.html

SCD_FILES  := $(wildcard $(SCD_DIR)/*.scd)
ROFF_FILES := $(patsubst $(SCD_DIR)/%.scd,$(ROFF_DIR)/%.roff,$(SCD_FILES))
HTML_FILES := $(patsubst $(ROFF_DIR)/%.roff,$(OUTPUT_DIR)/%.html,$(ROFF_FILES))

CNAME := danh.computer

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

# The following command obtains date on which the page was generated.
	$(eval tmp_date := $(shell grep '\.TH' $< | grep -oE '\d{4}-\d{2}-\d{2}'))
	$(eval page_date := $(shell date -jf "%Y-%m-%d" ${tmp_date} +"%B %-d, %Y"))

# The following command converts a ROFF file into HTML.
#
#   1. Omit the section header, as that's hardcoded in the template.
#
#   2. Omit the section footer, as that's partially hardcoded in the template,
#      and the rest we'll construct that ourselves.
#
#   3. Replace *bold* escape sequences with their HTML equivalent.
#
#   4. Fix spacing for resulting </b> tags. There might be extra spaces
#      before the tag and no space after it due to how nroff positions the
#      escape sequences.
#
#   5. Condense contiguous space characters after ',', '.', '?', and words
#      into a single space. In order to fully justify the text, nroff adds
#      additional spaces sometimes, so those extra spaces are removed here.
#
#   6. Replace *underline* escape sequences with their HTML equivalent.
#
#   7. Replace '{{content}}' in the page template with the man page.
#
#   8. Replace '{{title}}' in the page template with the man page's name.
#
#   9. Replace '{{date}}' in the page template with the page's creation date.
	@nroff -man $< \
		| tail +3 \
		| ghead -n -2 \
		| perl -pe 's/\x1b\[1m(.*?)\x1b\[(22|0)m/<b>\1<\/b>/gs' \
		| gsed -E -e 's/ +<\/b>/<\/b> /g' \
		| gsed -E -e 's/(,|\.|\?|\w) +(\w|<|[0-9])/\1 \2/g' \
		| perl -pe 's/\x1b\[4m(.*?)\x1b\[24m/<u>\1<\/u>/gs' \
		| gsed -E -e '/\{\{content\}\}/{r /dev/stdin' -e 'd;}' "$(TEMPLATE_FILE)" \
		| gsed -E -e 's/\{\{title\}\}/${title}/' \
		| gsed -E -e 's/\{\{date\}\}/${page_date}/' \
		> $@

$(ROFF_DIR):
	@mkdir -p $(ROFF_DIR)

$(OUTPUT_DIR): $(ROFF_DIR)
	@mkdir -p $(OUTPUT_DIR)

