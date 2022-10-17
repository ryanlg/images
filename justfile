# `justfile` for building and publishing various images used in the Ryhino project

# If we are running on Apple Slicion, force Docker to run on x86 instead.
DOCKER_PLATFORM := if arch() == "aarch64" { "--platform linux/amd64" } else { "" }
# Use Docker's `BuildKit` whenever possible
DOCKER := "DOCKER_BUILDKIT=1 docker"
# Username to publish the images to
DOCKER_PUBLISH_TO := "ryhino"
# Username to publish the images to
DOCKER_IIDFILE := "image.iid"


# Human-facing Recipes
# ====================
# Build dockerized GitLint for GitHub Workflow
ci_gitlint python_version gitlint_version:
    {{ DOCKER }} build \
      {{ DOCKER_PLATFORM }} \
      --build-arg GITLINT_VERSION={{ gitlint_version }} \
      --build-arg PYTHON_VERSION={{ python_version }} \
      --tag {{ DOCKER_PUBLISH_TO }}/ci-gitlint:dev \
      --iidfile {{DOCKER_IIDFILE}} \
      ci/gitlint


# CI-facing Recipes
# =================
# Build a Justfile `target` with `args`, tag the built image with `image_version`
_ci_build target image_version +args:
    just -v {{target}} {{args}}

    {{ DOCKER }} image tag \
      `cat ./{{DOCKER_IIDFILE}}` \
      {{ DOCKER_PUBLISH_TO }}/{{ target }}:{{ image_version }} \

    {{ DOCKER }} image tag \
      `cat ./{{DOCKER_IIDFILE}}` \
      {{ DOCKER_PUBLISH_TO }}/{{ target }}:latest \

# Push a built image tagged with `image_version`
_ci_push target image_version +args: (_ci_build target image_version args)
    docker image push {{ DOCKER_PUBLISH_TO }}/{{ target }}:{{ image_version }}
    docker image push {{ DOCKER_PUBLISH_TO }}/{{ target }}:latest

# GitHub Actions specific: parse a Git tag ref and invoke `just` with arguments
_gh_actions_parse ci_target ref:
    #!/usr/bin/env python3
    import subprocess, sys

    raw_ref = "{{ ref }}"
    if not raw_ref.startswith("ref/tags/"):
        raise ValueError(f'Unrecognizable tag ref: "{raw_ref}"')

    print(f'Git tag ref: "{raw_ref}"')

    raw_ref = raw_ref[9:]
    split_ref = raw_ref.split("-")  # In format of: target-image_version-args_to_just

    just_args = ["just", "-v", "{{ ci_target }}"] + split_ref
    print(f'Invoking just with: "{just_args}"')

    process = subprocess.run(["just", "-v", "{{ ci_target }}"] + split_ref)
    sys.exit(process.returncode)
