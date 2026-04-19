# Jenkins Shared Library

This folder contains reusable global vars and classes used by Jenkins pipelines.

## Layout

- `vars/`: Global steps callable from Jenkinsfiles.
- `src/`: Groovy classes under package structure.

## Usage

1. Register this repository as a Global Shared Library in Jenkins.
2. Load implicitly or with `@Library('your-library-name') _`.
3. Call shared steps such as `notifyBuild(...)` from pipelines.
