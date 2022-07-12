"""Module for propagating compilation providers."""

def _collect(*, cc_info, objc, is_xcode_target):
    """Collects compilation providers for a non top-level target.

    Args:
        cc_info: The `CcInfo` of the target, or `None`.
        objc: The `ObjcProvider` of the target, or `None`.
        is_xcode_target: Whether the target is an Xcode target.

    Returns:
        An opaque `struct` containing the linker input files for a target. The
        `struct` should be passed to functions in the `collect_providers` module
        to retrieve its contents.
    """
    is_xcode_library_target = cc_info and is_xcode_target

    return struct(
        _cc_info = cc_info,
        _objc = objc,
        _is_xcode_library_target = is_xcode_library_target,
    )

def _merge(*, transitive_compilation_providers):
    """Merges compilation providers from the deps of a target.

    Args:
        transitive_compilation_providers: A `list` of
            `(target(), XcodeProjInfo)` tuples of transitive dependencies that
            should have compilation providers merged.

    Returns:
        A value similar to the one returned from
        `compilation_providers.collect`.
    """
    cc_info = cc_common.merge_cc_infos(
        cc_infos = [
            providers._cc_info
            for _, providers in transitive_compilation_providers
            if providers._cc_info
        ],
    )

    objc_providers = [
        providers._objc
        for _, providers in transitive_compilation_providers
        if providers._objc
    ]
    if objc_providers:
        objc = apple_common.new_objc_provider(providers = objc_providers)
    else:
        objc = None

    return struct(
        _cc_info = cc_info,
        _is_xcode_library_target = False,
        _objc = objc,
        _transitive_compilation_providers = transitive_compilation_providers,
    )

def _get_xcode_library_targets(*, compilation_providers):
    """Returns the Xcode library target dependencies for this target.

    Args:
        compilation_providers: A value returned from
            `compilation_providers.merge`.

    Returns:
        A list of targets `struct`s that are Xcode library targets.
    """
    return [
        target
        for target, providers in (
            compilation_providers._transitive_compilation_providers
        )
        if providers._is_xcode_library_target
    ]

compilation_providers = struct(
    collect = _collect,
    get_xcode_library_targets = _get_xcode_library_targets,
    merge = _merge,
)