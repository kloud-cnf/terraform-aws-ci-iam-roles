## [0.3.1](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/compare/v0.3.0...v0.3.1) (2023-06-17)


### Bug Fixes

* **ci, policy:** fix template formatting ([e390f3f](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/commit/e390f3f4e589499cff15a4a3bc120f367f75c061))

# [0.3.0](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/compare/v0.2.3...v0.3.0) (2023-06-17)


### Features

* **iam, ci:** add org:* permission to ci policy ([0878c6e](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/commit/0878c6ea251e9fc47c1fad5084a0db69c2b732bb))

## [0.2.3](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/compare/v0.2.2...v0.2.3) (2023-06-17)


### Bug Fixes

* **iam, ci:** give ci-provisoner dynamodb perms ([6c6abfe](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/commit/6c6abfeb12b6a5bd69518522c63b1739b9bc5c9c))

## [0.2.2](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/compare/v0.2.1...v0.2.2) (2023-06-17)


### Bug Fixes

* **iam:** remove path from CI permission boundy policy ([4d0d178](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/commit/4d0d178626b75d23edcc553083a29c03222bc65b))

## [0.2.1](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/compare/v0.2.0...v0.2.1) (2023-06-17)


### Bug Fixes

* **iam, ci:** templated support for 'ci_admin' provisoner role with permission boundary ([3900962](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/commit/3900962b5472be05f92fae77ba3c3a1a53e7dab6))

# [0.2.0](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/compare/v0.1.0...v0.2.0) (2023-06-11)


### Features

* **iam:** support pull request event for roles created on github ([c0c3dc6](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/commit/c0c3dc67dc5cc3e225a46bf66743160199755030))

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Contents

- [0.1.0 (2023-05-28)](#010-2023-05-28)
    - [Features](#features)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# [0.1.0](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/compare/v0.0.0...v0.1.0) (2023-05-28)


### Features

* **module:** module support for creating CI role trust with OIDC trust ([#4](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/issues/4)) ([35c86e3](https://github.com/kloud-cnf/terraform-aws-ci-iam-roles/commit/35c86e3ef8266bea48ea02b0d29b43221975185f))
