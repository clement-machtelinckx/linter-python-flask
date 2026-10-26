# Declarative multi-arch build (needs a docker-container builder). `-f` is mandatory:
# bake would otherwise pick docker-compose.yml first.
# Run from the repository root (the secret path is relative) with secrets/pip_token.txt present.
# Default target is the local test registry, as seen from the builder on network tp2-net; that
# builder needs a buildkitd.toml marking the registry as plain HTTP:
#   [registry."tp2-registry:5000"]
#     http = true
#     insecure = true
#   docker buildx bake -f docker-bake.hcl
#   REGISTRY=ghcr.io/<owner> TAGS=v1.1.0,latest docker buildx bake -f docker-bake.hcl
variable "REGISTRY" {
  default = "tp2-registry:5000"
}

variable "IMAGE" {
  default = "linter-python-flask"
}

# Comma-separated in the environment, e.g. TAGS=v1.1.0,latest
variable "TAGS" {
  type    = list(string)
  default = ["dev"]
}

variable "CACHE_REF" {
  default = "${REGISTRY}/${IMAGE}:buildcache"
}

group "default" {
  targets = ["api"]
}

target "api" {
  context    = "."
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]
  tags       = [for tag in TAGS : "${REGISTRY}/${IMAGE}:${tag}"]
  secret     = ["id=pip_token,src=secrets/pip_token.txt"]
  cache-from = ["type=registry,ref=${CACHE_REF}"]
  cache-to   = ["type=registry,ref=${CACHE_REF},mode=max"]
  # A multi-arch result cannot be --load-ed: publish the unified index instead.
  output     = ["type=registry"]
}
