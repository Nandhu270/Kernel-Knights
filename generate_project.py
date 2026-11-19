#!/usr/bin/env python3
import os
import hashlib

def make_id(key):
    return hashlib.md5(key.encode('utf-8')).hexdigest()[:24].upper()

root_dir = "LabRecordBook"
swift_files = []
for dirpath, _, filenames in os.walk(root_dir):
    for f in filenames:
        if f.endswith(".swift"):
            rel_path = os.path.join(dirpath, f)
            swift_files.append(rel_path)

swift_files.sort()

# IDs
proj_id = make_id("PROJECT")
main_group_id = make_id("MAIN_GROUP")
products_group_id = make_id("PRODUCTS_GROUP")
product_ref_id = make_id("PRODUCT_REF")
target_id = make_id("TARGET")
sources_phase_id = make_id("SOURCES_PHASE")
frameworks_phase_id = make_id("FRAMEWORKS_PHASE")
resources_phase_id = make_id("RESOURCES_PHASE")
proj_config_list_id = make_id("PROJ_CONFIG_LIST")
target_config_list_id = make_id("TARGET_CONFIG_LIST")
proj_debug_config_id = make_id("PROJ_DEBUG_CONFIG")
proj_release_config_id = make_id("PROJ_RELEASE_CONFIG")
target_debug_config_id = make_id("TARGET_DEBUG_CONFIG")
target_release_config_id = make_id("TARGET_RELEASE_CONFIG")

# File references & build files
build_files = []
file_refs = []
sources_entries = []

for s in swift_files:
    fname = os.path.basename(s)
    f_ref_id = make_id(f"FILE_REF_{s}")
    b_file_id = make_id(f"BUILD_FILE_{s}")
    
    file_refs.append(f'\t\t{f_ref_id} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{fname}"; sourceTree = "<group>"; }};')
    build_files.append(f'\t\t{b_file_id} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {f_ref_id} /* {fname} */; }};')
    sources_entries.append(f'\t\t\t\t{b_file_id} /* {fname} in Sources */,')

# Info.plist file reference
plist_ref_id = make_id("FILE_REF_INFO_PLIST")
file_refs.append(f'\t\t{plist_ref_id} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "Info.plist"; sourceTree = "<group>"; }};')

# Group structure
# Groups: App, Models, Data, Services, ViewModels, Views, Components
groups_dict = {}
for s in swift_files:
    parts = s.split(os.sep)
    # parts: ['LabRecordBook', 'SubDir', ..., 'File.swift']
    cur = "LabRecordBook"
    for p in parts[1:-1]:
        cur_parent = cur
        cur = cur + "/" + p
        if cur_parent not in groups_dict:
            groups_dict[cur_parent] = []
        if cur not in groups_dict[cur_parent]:
            groups_dict[cur_parent].append(cur)
    if cur not in groups_dict:
        groups_dict[cur] = []
    groups_dict[cur].append(s)

# Add Info.plist to LabRecordBook root group
if "LabRecordBook" not in groups_dict:
    groups_dict["LabRecordBook"] = []
groups_dict["LabRecordBook"].append("LabRecordBook/Info.plist")

pbx_groups = []

# Main group
main_children = [
    f'{make_id("GROUP_LabRecordBook")} /* LabRecordBook */',
    f'{products_group_id} /* Products */'
]
main_children_str = "\n".join([f'\t\t\t\t{c},' for c in main_children])
pbx_groups.append(f'''\t\t{main_group_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{main_children_str}
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};''')

# Products group
pbx_groups.append(f'''\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{product_ref_id} /* LabRecordBook.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};''')

# Other groups
for g_path, items in sorted(groups_dict.items()):
    g_id = make_id(f"GROUP_{g_path}")
    g_name = os.path.basename(g_path)
    children = []
    for item in items:
        if item in swift_files:
            fname = os.path.basename(item)
            f_ref_id = make_id(f"FILE_REF_{item}")
            children.append(f'{f_ref_id} /* {fname} */')
        elif item == "LabRecordBook/Info.plist":
            children.append(f'{plist_ref_id} /* Info.plist */')
        else:
            # Subgroup
            sub_id = make_id(f"GROUP_{item}")
            sub_name = os.path.basename(item)
            children.append(f'{sub_id} /* {sub_name} */')
    children_str = "\n".join([f'\t\t\t\t{c},' for c in children])
    pbx_groups.append(f'''\t\t{g_id} /* {g_name} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children_str}
\t\t\t);
\t\t\tpath = "{g_name}";
\t\t\tsourceTree = "<group>";
\t\t}};''')

build_files_str = "\n".join(build_files)
file_refs_str = "\n".join(file_refs)
sources_entries_str = "\n".join(sources_entries)
pbx_groups_str = "\n".join(pbx_groups)

project_content = f'''// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{build_files_str}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		{product_ref_id} /* LabRecordBook.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = LabRecordBook.app; sourceTree = BUILT_PRODUCTS_DIR; }};
{file_refs_str}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase_id} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
{pbx_groups_str}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_id} /* LabRecordBook */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {target_config_list_id} /* Build configuration list for PBXNativeTarget "LabRecordBook" */;
			buildPhases = (
				{sources_phase_id} /* Sources */,
				{frameworks_phase_id} /* Frameworks */,
				{resources_phase_id} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = LabRecordBook;
			productName = LabRecordBook;
			productReference = {product_ref_id} /* LabRecordBook.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{proj_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{target_id} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {proj_config_list_id} /* Build configuration list for PBXProject "LabRecordBook" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group_id};
			productRefGroup = {products_group_id} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_id} /* LabRecordBook */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase_id} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase_id} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{sources_entries_str}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{proj_debug_config_id} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{proj_release_config_id} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			}};
			name = Release;
		}};
		{target_debug_config_id} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = LabRecordBook/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.kernelknights.LabRecordBook;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
				OTHER_SWIFT_FLAGS = "-disable-sandbox";
				CLANG_MODULE_CACHE_PATH = "/tmp/ModuleCache";
				UISUPPORTED_INTERFACE_ORIENTATIONS = UIInterfaceOrientationPortrait;
			}};
			name = Debug;
		}};
		{target_release_config_id} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = LabRecordBook/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.kernelknights.LabRecordBook;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
				OTHER_SWIFT_FLAGS = "-disable-sandbox";
				CLANG_MODULE_CACHE_PATH = "/tmp/ModuleCache";
				UISUPPORTED_INTERFACE_ORIENTATIONS = UIInterfaceOrientationPortrait;
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{proj_config_list_id} /* Build configuration list for PBXProject "LabRecordBook" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{proj_debug_config_id} /* Debug */,
				{proj_release_config_id} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{target_config_list_id} /* Build configuration list for PBXNativeTarget "LabRecordBook" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{target_debug_config_id} /* Debug */,
				{target_release_config_id} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */

	}};
	rootObject = {proj_id} /* Project object */;
}}
'''

os.makedirs("LabRecordBook.xcodeproj", exist_ok=True)
with open("LabRecordBook.xcodeproj/project.pbxproj", "w") as f:
    f.write(project_content)

print("LabRecordBook.xcodeproj/project.pbxproj generated successfully!")
