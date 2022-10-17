# Dockerized GitLint for Github Workflow

ARG PYTHON_VERSION
ARG GITLINT_VERSION
FROM python:$PYTHON_VERSION-slim

ARG GITLINT_VERSION
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    pip install gitlint~=$GITLINT_VERSION

# $GITHUB_WORKSPACE should be mounted to the container
ADD ./.gitlint /github-workspace/

# Run GitLint
WORKDIR /github-workspace/
CMD ["gitlint", "--commits", "origin/main..HEAD"]
