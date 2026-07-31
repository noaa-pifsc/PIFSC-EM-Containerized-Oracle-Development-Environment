# PIFSC EM Containerized Oracle Developer Environment

## Overview
The PIFSC Containerized Oracle Developer Environment (CODE) project was developed to provide a containerized Oracle development environment for PIFSC software developers. The Electronic Monitoring (EM) was forked from the CODE project or a downstream forked CODE project to extend the CODE project's functionality and integrate EM's dependencies. This repository can be forked to extend the existing functionality to any data systems that depend on the EM for both development and testing purposes.

## Resources
-   ### Version Control Information
    -   URL: git@github.com:noaa-pifsc/PIFSC-EM-Containerized-Oracle-Development-Environment.git
    -   Version: 1.0 (git tag: EM_CODE_v1.0)
    -   Upstream Repositories (in order from direct parent to top-level parent):
        -   CODE Version Control Information:
            -   URL: git@github.com:noaa-pifsc/PIFSC-Containerized-Oracle-Development-Environment.git
            -   Version: 1.4 (git tag: CODE_v1.4)

## Intended Use
-   Refer to the CODE [Intended Use](../../../../core/docs/CODE%20Documentation.md#intended-use) documentation for details

## Requirements
-   Refer to the CODE [Requirements](../../../../core/docs/CODE%20Documentation.md#requirements) documentation for details

## Container Host Instances
-   Refer to the CODE [Container Host Instances](../../../../core/docs/CODE%20Documentation.md#container-host-instances) documentation for details

## Dependencies
-   Refer to the CODE [Dependencies](../../../../core/docs/CODE%20Documentation.md#dependencies) for details
-   Custom Dependencies:
    -   ### EM Version Control Information
        -   folder path: [/projects/EM/modules/EM](../../EM/modules/EM) 
        -   Version Control Information:
            -   URL: <git@github.com:WPacFIN/em-database.git>
            -   Version 0.1 (git tag: em_db_v0.1)

## Container Architecture
-   Refer to the CODE [Container Architecture](../../../../core/docs/CODE%20Documentation.md#container-architecture) documentation for details

## Naming Conventions
-   Refer to the CODE [Repository Fork Diagram](../../../../core/docs/CODE%20Documentation.md#naming-conventions) documentation for details

## Repository Fork Diagram
-   Refer to the CODE [Repository Fork Diagram](../../../../core/docs/CODE%20Documentation.md#repository-fork-diagram) documentation for details

# CODE Folder Structure
-   Refer to the CODE [Folder Structure](../../../../core/docs/CODE%20Documentation.md#code-folder-structure) documentation for details

## CODE Business Rules
-   Refer to the CODE [Business Rules](../../../../core/docs/CODE%20Documentation.md#code-business-rules) documentation for details

## CODE Implementation Procedure
-   Refer to the CODE [Implementation Procedure](../../../../core/docs/CODE%20Documentation.md#code-implementation-procedure) documentation for details

## Setup
-   Refer to the CODE [Setup](../../../../core/docs/CODE%20Documentation.md#setup) documentation for details

## Executing the CODE Project
-   Refer to the [Executing the CODE Project](../../../../core/docs/CODE%20Documentation.md#executing-the-code-project) documentation for details

## Contribution and Repository Management Guidelines
-   Refer to the [Contribution and Repository Management Guidelines](../../../../core/docs/CODE%20Documentation.md#contribution-and-repository-management-guidelines) documentation for details

## Monitoring and Syncing Upstream Updates
-   Refer to the [Monitoring and Syncing Upstream Updates](../../../../core/docs/CODE%20Documentation.md#monitoring-and-syncing-upstream-updates) documentation for details

## Connection Information
-   Refer to the CODE [Connection Information](../../../../core/docs/CODE%20Documentation.md#connection-information) documentation for details
    -   The individual account passwords can be found in the /secrets/secrets.sh file 

## Security Features
-   Refer to the CODE [Security Features](../../../../core/docs/CODE%20Documentation.md#security-features) documentation for details

## Design Strategy
-   Refer to the [CODE Design Strategy](../../../../core/docs/CODE%20Documentation.md#design-strategy) documentation for details
    -   Benefits:
        -   Reduce the amount of custom code needed to deploy this CODE fork