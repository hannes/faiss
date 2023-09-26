.PHONY: all clean format debug release duckdb_debug duckdb_release pull update

all: release

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJ_DIR := $(dir $(MKFILE_PATH))

OSX_BUILD_UNIVERSAL_FLAG=
ifeq (${OSX_BUILD_UNIVERSAL}, 1)
	OSX_BUILD_UNIVERSAL_FLAG=-DOSX_BUILD_UNIVERSAL=1
endif
ifeq (${STATIC_LIBCPP}, 1)
	STATIC_LIBCPP=-DSTATIC_LIBCPP=TRUE
endif

ifeq ($(GEN),ninja)
	GENERATOR=-G "Ninja"
	FORCE_COLOR=-DFORCE_COLORED_OUTPUT=1
endif

BUILD_FLAGS=-DEXTENSION_STATIC_BUILD=1 -DBUILD_TPCH_EXTENSION=1 -DBUILD_PARQUET_EXTENSION=1 ${OSX_BUILD_UNIVERSAL_FLAG} ${STATIC_LIBCPP}

CLIENT_FLAGS :=

# These flags will make DuckDB build the extension
EXTENSION_NAME=FAISS
EXTENSION_NAME_LOWER=faiss
EXTENSION_FLAGS=-DDUCKDB_EXTENSION_NAMES="${EXTENSION_NAME_LOWER}" -DDUCKDB_EXTENSION_${EXTENSION_NAME}_PATH="$(PROJ_DIR)" -DDUCKDB_EXTENSION_${EXTENSION_NAME}_SHOULD_LINK="TRUE" -DDUCKDB_EXTENSION_${EXTENSION_NAME}_INCLUDE_PATH="$(PROJ_DIR)src/include"

pull:
	git submodule init
	git submodule update --recursive --remote

clean:
	rm -rf build
	rm -rf testext
	cd duckdb && make clean
	cd duckdb && make clean-python
	rm -rf libomp

# Main build
debug:
	mkdir -p  build/debug && \
	cmake $(GENERATOR) $(FORCE_COLOR) $(EXTENSION_FLAGS) ${CLIENT_FLAGS} -DEXTENSION_STATIC_BUILD=1 -DCMAKE_BUILD_TYPE=Debug ${BUILD_FLAGS} -S ./duckdb/ -B build/debug && \
	cmake --build build/debug --config Debug

release:
	mkdir -p build/release && \
	cmake $(GENERATOR) $(FORCE_COLOR) $(EXTENSION_FLAGS) ${CLIENT_FLAGS} -DEXTENSION_STATIC_BUILD=1 -DCMAKE_BUILD_TYPE=Release ${BUILD_FLAGS} -S ./duckdb/ -B build/release && \
	cmake --build build/release --config RelWithDebInfo

# Client build
debug_js: CLIENT_FLAGS=-DBUILD_NODE=1 -DDUCKDB_EXTENSION_${EXTENSION_NAME}_SHOULD_LINK=0
debug_js: debug

debug_python: CLIENT_FLAGS=-DBUILD_PYTHON=1 -DBUILD_JSON_EXTENSION=1 -DBUILD_FTS_EXTENSION=1 -DBUILD_TPCH_EXTENSION=1 -DBUILD_VISUALIZER_EXTENSION=1 -DBUILD_TPCDS_EXTENSION=1
debug_python: debug

release_js: CLIENT_FLAGS=-DBUILD_NODE=1 -DDUCKDB_EXTENSION_${EXTENSION_NAME}_SHOULD_LINK=0
release_js: release

release_python: CLIENT_FLAGS=-DBUILD_PYTHON=1 -DDUCKDB_EXTENSION_${EXTENSION_NAME}_SHOULD_LINK=0
release_python: release

# Main tests
test: test_release

test_release: release
	./build/release/test/unittest --test-dir . "[sql]"

test_debug: debug
	./build/debug/test/unittest --test-dir . "[sql]"

# Client tests
DEBUG_EXT_PATH='$(PROJ_DIR)build/debug/extension/${EXTENSION_NAME_LOWER}/${EXTENSION_NAME_LOWER}.duckdb_extension'
RELEASE_EXT_PATH='$(PROJ_DIR)build/release/extension/${EXTENSION_NAME_LOWER}/${EXTENSION_NAME_LOWER}.duckdb_extension'
test_js: test_debug_js
test_debug_js: debug_js
	cd duckdb/tools/nodejs && ${EXTENSION_NAME}_EXTENSION_BINARY_PATH=$(DEBUG_EXT_PATH) npm run test-path -- "../../../test/nodejs/**/*.js"

test_release_js: release_js
	cd duckdb/tools/nodejs && ${EXTENSION_NAME}_EXTENSION_BINARY_PATH=$(RELEASE_EXT_PATH) npm run test-path -- "../../../test/nodejs/**/*.js"

test_python: test_debug_python
test_debug_python: debug_python
	cd test/python && ${EXTENSION_NAME}_EXTENSION_BINARY_PATH=$(DEBUG_EXT_PATH) python3 -m pytest

test_release_python: release_python
	cd test/python && ${EXTENSION_NAME}_EXTENSION_BINARY_PATH=$(RELEASE_EXT_PATH) python3 -m pytest

create_msmarco_index:
	cd conformanceTests && python make_index.py

conformanceTests/index: create_msmarco_index

run_msmarco_queries: conformanceTests/index
	cd conformanceTests && python execute_queries.py

install_local: install_release_local
install_release_local: release
	echo "INSTALL \"$(RELEASE_EXT_PATH)\"" | build/release/duckdb 
install_debug_local: debug
	echo "INSTALL \"$(DEBUG_EXT_PATH)\"" | build/release/duckdb 

format:
	find src/ -iname *.hpp -o -iname *.cpp | xargs clang-format --sort-includes=0 -style=file -i
	cmake-format -i CMakeLists.txt

update:
	git submodule update --remote --merge
