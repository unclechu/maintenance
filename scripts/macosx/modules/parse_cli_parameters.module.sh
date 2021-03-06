#####################################################################
# This function parses CLI parameters and set some variables
# dedicated for them.
#####################################################################
function parse_cli_parameters()
{
    log "Parsing CLI parameters..."
    log "======================================== BUILD PARAMETERS"
    local cliparams=$@

    # Build Psi or Psi+?
    if [ "${cliparams/build-plain-psi}" != "${cliparams}" ]; then
        log "Building plain Psi, without patches."
        BUILD_PSI=1
        BUILD_PSI_PLUS=0
        WE_WILL_BUILD="Psi"
    else
        log "Building ${WE_WILL_BUILD}"
        # Do nothing as we're defaulting to Psi+.
    fi

    # Build from snapshot or git?
    if [ "${cliparams/build-from-snapshot}" != "${cliparams}" ]; then
        log "Building from snapshotted sources"
        BUILD_FROM_SNAPSHOT=1
        SKIP_GENERIC_PATCHES=1
    else
        log "Building from git sources"
        BUILD_FROM_SNAPSHOT=0
        SKIP_GENERIC_PATCHES=0
    fi

    # Webkit build.
    if [ "${cliparams/enable-webengine}" != "${cliparams}" ]; then
        log "Enabling WebEngine build"
        ENABLE_WEBENGINE=1
    else
        log "Will not build WebEngine version"
        ENABLE_WEBENGINE=0
    fi

    # All translations.
    if [ "${cliparams/bundle-all-translations}" != "${cliparams}" ]; then
        log "Enabling bundling all translations"
        BUNDLE_ALL_TRANSLATIONS=1
    else
        log "Will install only these translations: ${TRANSLATIONS_TO_INSTALL}"
        BUNDLE_ALL_TRANSLATIONS=0
    fi

    # Dev plugins.
    if [ "${cliparams/enable-dev-plugins}" != "${cliparams}" ]; then
        log "Enabling unstable (dev) plugins"
        ENABLE_DEV_PLUGINS=1
    else
        log "Will not build unstable (dev) plugins"
        ENABLE_DEV_PLUGINS=0
    fi

    # Portable?
    if [ "${cliparams/make-portable}" != "${cliparams}" ]; then
        log "Enabling portable mode"
        PORTABLE=1
    else
        log "Will not be portable"
        PORTABLE=0
    fi

    # Skip bad patches?
    if [ "${cliparams/skip-bad-patches}" != "${cliparams}" ]; then
        log "Will not apply bad patches."
        SKIP_BAD_PATCHES=1
    else
        log "Will not continue on bad patch"
        SKIP_BAD_PATCHES=0
    fi

    # Use Qt5 from website?
    if [ "${cliparams/use-qt5-from-website}" != "${cliparms}" ]; then
        log "Will try to use Qt5 installed from website."
        USE_QT5_FROM_WEBSITE=1
    else
        log "Will NOT try to use Qt5 installed from website."
        USE_QT5_FROM_WEBSITE=0
    fi
    log "========================================"
}
