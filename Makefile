XESTI_XML_DOCS_DIR?=./docs
XESTI_XML_PRODUCT?=XestiXML

HOSTING_BASE_PATH=$(XESTI_XML_PRODUCT)

.PHONY: all build clean lint preview publish reset test update

all: clean update build

build:
	@ swift build -c release

clean:
	@ swift package clean

lint:
	@ swiftlint lint --fix
	@ swiftlint lint

preview:
	@ open "http://localhost:8080/documentation/xestixml"
	@ swift package --disable-sandbox                     \
					preview-documentation                 \
					--enable-inherited-docs               \
					--experimental-documentation-coverage \
					--product $(XESTI_XML_PRODUCT)

publish:
	@ swift package --allow-writing-to-directory $(XESTI_XML_DOCS_DIR) \
					generate-documentation                             \
					--disable-indexing                                 \
					--enable-inherited-docs                            \
					--experimental-documentation-coverage              \
					--hosting-base-path $(HOSTING_BASE_PATH)           \
					--output-path $(XESTI_XML_DOCS_DIR)                \
					--product $(XESTI_XML_PRODUCT)                     \
					--transform-for-static-hosting

reset:
	@ swift package reset

test:
	@ swift test --enable-code-coverage

update:
	@ swift package update
