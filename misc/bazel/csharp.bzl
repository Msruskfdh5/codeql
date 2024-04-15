load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary", "csharp_library", "publish_binary")

TARGET_FRAMEWORK = "net8.0"

def codeql_csharp_library(name, **kwargs):
    nullable = kwargs.pop("nullable", "enable")
    target_frameworks = kwargs.pop("target_frameworks", [TARGET_FRAMEWORK])
    csharp_library(name = name, nullable = nullable, target_frameworks = target_frameworks, **kwargs)

def codeql_csharp_binary(name, **kwargs):
    nullable = kwargs.pop("nullable", "enable")
    visibility = kwargs.pop("visibility", ["//visibility:public"])
    target_frameworks = kwargs.pop("target_frameworks", [TARGET_FRAMEWORK])
    csharp_binary_target = name + ".bin"
    csharp_binary(name = csharp_binary_target, nullable = nullable, target_frameworks = target_frameworks, **kwargs)
    publish_binary(
        name = name,
        binary = csharp_binary_target,
        self_contained = True,
        visibility = visibility,
        target_framework = TARGET_FRAMEWORK,
        runtime_identifier = select(
            {
                "@platforms//os:macos": "osx-x64",  # always force intel on macos for now, until we build universal binaries
                "//conditions:default": "",
            },
        ),
    )
