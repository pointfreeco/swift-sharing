format:
	swift format . --recursive --in-place

docker-build:
	docker run --rm -v "$(PWD):$(PWD)" -w "$(PWD)" swift:6.0 bash -c "swift build"

.PHONY: format
