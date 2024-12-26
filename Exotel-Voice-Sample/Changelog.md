# Changelog 

All notable changes to this project will be documented in this file.

## [1.0.12] 20-11-2024
* [VST-899]
  ** Added a call to self.onSipStarted() during the Cloudonix initialization process and updated the stop() function to ensure it waits for the completion of each function before proceeding to the next.

## [1.0.11] 25-11-2024
* [VST-881]
  ** Adding delay in stop function, and checking system state (Fatal message crash fix)

## [1.0.10] 30-09-2024
* [VST-842]
** pj_pool_release crash fix 
** pj_lock_acquire crash fix


## [1.0.8] 23-09-2024
* [VST-842]
** exposed event for onInitializationDelay if sdk intialization takes more than 5 sec 
** appendLog crash fix for EXC_BREAKPOINT

## [v1.0.7] 25-07-2024

### Added
*[VST-801] configuration sending event metrics

## [unreleased]

### Added
* [AP2AP-245](https://exotel.atlassian.net/browse/AP2AP-245) : using new bluetooth toggeling APIs to topgle audio
* [AP2AP-207](https://exotel.atlassian.net/browse/AP2AP-207) : integrated call kit UI
* [VST-668](https://exotel.atlassian.net/browse/VST-668) : resolved ios simulator build issue and  added xcframework .
* using new stop and onDeitinialized API introduced in sdk version 1.0.4

## [v1.0 build 92] 28-08-2023

### Added
* [AP2AP-196](https://exotel.atlassian.net/browse/AP2AP-196) : added contact search support

## [v1.0 build 91]  25-08-2023

### Added
* [AP2AP-187](https://exotel.atlassian.net/browse/AP2AP-187) : added whatsapp support

## [v1.0 build 90]  07-08-2023

### Changed
*   [AP2AP-175](https://exotel.atlassian.net/browse/AP2AP-175) : hide the multi call options and added Environmental flag HIDE_MULTI_CALL to control the visibilty of multi call option

### Fixed
*  [AP2AP-174](https://exotel.atlassian.net/browse/AP2AP-174) : fixed crash due to timeformat of 12h  