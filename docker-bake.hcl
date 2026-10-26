variable "REGISTRY" { default = "ghcr.io" }
variable "OWNER" { default = "clement-machtelinckx" }
variable "IMAGE_NAME" { default = "linter-python-flask" }
variable "VERSION" { default = "local" }
variable "CACHE_REF" { default = "ghcr.io/clement-machtelinckx/linter-python-flask:buildcache" }
variable "BUILD_TOKEN_FILE" { default = ".secrets/build-token" }
variable "OCI_DEST" { default = "security-evidence/image.oci.tar" }

group "default" { targets = ["local"] }

target "common" {
  context = "."
  dockerfile = "Dockerfile"
  secret = ["id=build_token,src=${BUILD_TOKEN_FILE}"]
  tags = ["${REGISTRY}/${OWNER}/${IMAGE_NAME}:${VERSION}"]
}

target "local" {
  inherits = ["common"]
  platforms = ["linux/amd64"]
  tags = ["linter-python-flask-api:local"]
  output = ["type=docker"]
  attest = ["type=provenance,disabled=true"]
}

target "arm64" {
  inherits = ["local"]
  platforms = ["linux/arm64"]
  tags = ["linter-python-flask-api:arm64"]
}

target "multiarch" {
  inherits = ["common"]
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = ["type=registry,ref=${CACHE_REF}"]
  cache-to = ["type=registry,ref=${CACHE_REF},mode=max"]
  output = ["type=oci,dest=${OCI_DEST}"]
}

target "publish" {
  inherits = ["multiarch"]
  output = ["type=registry"]
}
